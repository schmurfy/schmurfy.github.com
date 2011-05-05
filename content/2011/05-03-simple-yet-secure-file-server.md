---
title: Simple yet secure file server
kind: article
tags: [sinatra, ruby, nginx, redis]
created_at: 2011/05/03 22:00
---

This is a problem I faced many times but did not had the opportunity to find a good approach to the problem,
recently I faced it once again and found what i consider a really nice way to implement it efficiently and securely.

## The problem

The problem is quite simple to describe: how can you serve a file to a given client without allowing it full
access to the repository, and serves it fast and efficiently resources wise.

## My environment

Here are some background on my environment to better understand why I did things that way: The application I work
on is already made of multiple distinct ruby servers/daemons speaking to each other using an in house network protocol,
aside of those I already have a redis server used mostly for caching data.


## Let's get to work !

Among time I tried different solutions to this problem:

### The worst method

  You set up a webserver to serve a defined folder where all your files are
  and your disable the autoindex feature.
  
  The problems are:
  
  - if someone have he link it can download again the file whenever he wants
    (it may or may not be a problem depending on your usage)
  - a client with the link can pass it to anyone to download the file
  - a client may guess another file's path and download it
  
  The last time I used this method the filenames were alphanumeric strings
  of 32 characters, this at least reduce the guessing risk to nearly zero


### The second, slightly better

  We now have a web application (php, ruby, perl, etc...) which serves the pages
  to the clients, the files are stored on the disk outside the webserver root and so, are not
  accessible directly by clients.

  The application authenticate the client (how it is done is irrelevant here) and then the
  application sends the file's content itself to the client.

  The problems:
  
  - You monopolize one instance of your application for this task (it is
    especially a problem with ruby on rails)
  - chances are that streaming the file through your application will slow down
    the transfer speed and it can takes more resources on the server.

  At least with this approach a client can no longer access a file we don't want him
  to download and even if he manages to guess another file's name he will just be rejected.
  
  Clients can still exchanges login/pass but that's another story, let's consider that our
  clients here do not share passwords.

### Now we talk

  I know this is not a terribly big news but apache have support for sending files directly
  to a client when asked by an application running below it, when an application returns
  an header "X-Sendfile" pointing to an absolute path on the webserver disk then this file
  will be streamed by apache to the client.
  
  Nginx has a similar feature but it works differently, here is an example config file:
  
<pre class="language-nginx">
server {
  listen 3000;

  location / {
    root '[...]/public';

    passenger_enabled on;
    passenger_min_instances 1;
  }

  location "/data" {
    internal;
    root "/path/to/data";
  }
}
</pre>
  
  We have a sinatra application running under passenger on port 3000 and we declare
  an internal location where our files are, the /data path will not be accessible
  for web clients.
  
  Now the next part is to send the required headers, here is what a minimal sinatra
  application looks like for doing this:
<pre class="language-ruby">
require 'rubygems'
require 'sinatra'

get "/:token/*" do
  # we use splat here to allow the path to include "/"
  path = params[:splat].join('/')
  content_type 'application/x-zip'

  headers(
      # Set the filename for the browser, you can force it
      # or just use the original one ( File.basename(path) )
      "Content-Disposition" => "attachment; filename=\"file.txt\"",
      
      # and ask nginx to send this file to the client
      "X-Accel-Redirect" => "/data/#{path}"
    )
  
  # finally return an empty body
  return ""
end
</pre>
  
  This is a minimal application, no authentication, no security check.
  Now if we want a full application we need some kind of strategy to ensure the client
  have access to the file he asked, I did this by using redis:
  
  When a client wants a file he first needs to ask our main application (this is
  the one he is connected to), this application will respond with a token and a path (
  the token is saved in the redis database and set to expire in a fixed delay),
  the client will then ask the file server for this file with the token just received,
  here is the complete sinatra application:
  
<pre class="language-ruby">
require 'rubygems'
require 'sinatra'
require 'redis'


get "/:token/*" do
  # Connect to the redis database
  redis = Redis.new
  # check the specified token
  allowed_path = redis.get("file_download:#{params[:token]}")
  path = params[:splat].join('/')

  # only only passage if the token exists and the path asked
  # is the same as the one associated with the token in redis
  if path && (allowed_path == path)
    # set the content type so the browser reacts as expected
    content_type 'xxx/yyy'

    headers(
        "Content-Disposition" => %{attachment; filename="file.ext"},
        "X-Accel-Redirect" => "/data/#{path}"
      )
    return ""
  else
    # return a 404 if access is refused
    # so the client have no way to tells if access was refused
    # or the file really does not exists
    raise Sinatra::NotFound
  end
end  
</pre>
  
  Since the keys in redis have an expiration delay the client is only allowed to
  access the file once and has to make another request to download it again.
  
  The expiration delay can even be really short since the check is done at the
  start of the download, having a too short delay may cause more problems though
  if the client need to retry the download for any reason.

## Conclusion
  Thanks to redis (it would also work with any database actually) you can distribute the
  roles between your applications as you wish and with the configuration shown above any
  application in your environment could deliver a pass to access a given file allowing
  them to share a single "file server" and still maintaining tight access control.
  
  Following the same idea we could also register a number of allowed downloads in redis
  and decrement the counter each time the url is accessed, the atomic nature of redis
  operations makes this really easy to do.
  





