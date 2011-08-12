---
title: "Building a Rack Middleware with sinatra"
kind: article
tags: [ruby, sinatra, rack]
created_at: 2011/08/12 14:00
---

I recently had the need to separate some logic from my main web application, after thinking
about it for a while (months actually) I finally got an illumination: what about rack ?  
After a quick test aside of my project I confirmed that building a rack middleware is really easy
( even easier that I thought ), this article is a quick tutorial to build a simple middleware.

## What is rack ?

Rack is a library used in the Ruby to standardize the interactions between the different frameworks
we have and the web server themselves, thanks to Rack we can now build part of an application in
sinatra, another in rails, etc...  
Rack is a really nice piece of software but I doubt many out there really used it directly,
I knew it for quite a long time now but never really felt the need to dig in it.

You can learn more about Rack [rack](http://rack.rubyforge.org/ "here")


## Our middleware

The middleware will simply serve an url with sinatra, I consider this simple enough
to get anyone interested started, based on this you can do nearly anything.  
The middleware will also accept parameters since I had to do some search to found out
how to do it.

    :ruby
    require 'rack'
    require 'sinatra/base'

    class AboutApp < Sinatra::Base
      def initialize(app, opts)
        @name = opts.delete(:name)
      end

      get '/about' do
        "Hello, my name is #{@str} !"
      end
    end


And here is a config.ru file showing how to use it:

    :ruby
    
    require 'about_app'
    
    # this class will act as our main application
    class MyApp < Sinatra::Base
      get '/test' do
        "Test it yourself !"
      end
    end


    use AboutApp, :name => "Julien"
    run MyApp

And that is really all you need, now you can run your application with any rack compliant
web server which basically means you can run it on every web server supporting ruby ;)

For example:

    :bash
    $ unicorn

