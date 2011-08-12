---
title: Ruby Application Monitoring
kind: article
tags: [ruby, monitoring, metrics, collectd]
created_at: 2011/05/19 22:30
---

When any of your applications starts to really fly by themselves you are bound to reach a
point where you want/need to know what happen inside it and translate that into graphs
you can show and monitor to check the health of the system.

Such a system include many parts that must work together to bring you the data you want
and/or want to show and that is where I faced my first wall.

## What are those parts ?

### Producer
Your applications can produce data you want to store and view immediately or later,
a general purpose probe can also extract useful metrics from a physical server like
the cpu usage, the load, memory, etc...<br/>

### Aggregator / Router
This node is the one receiving the data and deciding what to do with them, whether
it will be stored on a local disk in rrd or send on the network to another application
and whether to use the data as is or to transform them before.<br/>

### Storage Engine
I decided to separate this one but most of the time it will be a subpart of the
Aggregator / Router. The storage will determine how and where your data will be
stored, most of the time it will be rrd since it works and there are not real
alternatives out there.<br/>
While the rrd format itself is nice I am not really too fond of the rrd library
itself, the api is really ugly and always force me to do things I do not want
to do whenever I need to work with it.

### Graph drawer
That is the last part and will surely be the most important since whatever
energy/dedication you put in setting up the other parts it is that one anyone
will face and that is also one of my biggest problem...


## Choosing the right parts

There are some beast out there that are heavily used when you start speaking about monitoring
you are nearly forced to hit them (or get it by them), the name I hear the most are:
Nagios, Munin, Cacti, MRTG, SmokePing.

There a multiple problems for me with those systems, the first one is that some
are more or less focused on a specific need (like SmokePing) and making them play
together can be really "fun", the kind of fun nobody wants.<br>
The other problem I faced is that they tend to want control over the whole monitoring system,
they want you to use their producers module, their graph drawer, their router and if
you want to step aside and change one part your are doomed.<br/>
It may have changed since last time I did a check but I highly doubt it.

I worked with some of those in the past but never really liked them so when I
faced again the need to collect metrics from different applications/languages
as well as server's metrics I tried to find something else.

### The SmokePing case
Before I started working on a monitoring solution for a work project I am currently
on there was previously SmokePing set up, I may be heavily biased on it
because of my first impression but what first impression it made&nbsp;!

The first things I noticed when looking at it was that the server part was slow as hell
and was taking a more than noticeable part of the cpu (I honestly do not
remember how much but it was certainly not invisible on the machine speaking
of resources) so I checked its producer counterpart which is on an embedded system
(Soekris hardware) and here too the daemon was not invisible at all !

The last thing that crushed that beast for me is that loading a page with graphs on
it was slow too and caused cpu spikes, perfect !

It is perfectly possible that smokeping was badly installed and would work
far better in normal conditions (that said I am not too sure about the producer part)
but seriously what can you do with such bright first impression ?


### Enter Collectd

While looking for a decent Aggregator I came upon collectd which I never saw
before and does a really great job at dispatching metrics.

Collectd is a modular application with modules falling in two categories:

- readers: these plugins receive data from somewhere or extract it (ex: 
network, shell command, /proc file, etc...)

- writers: these plugins will output the data somewhere (ex: network again,
rrdtool, rrdcached, database, etc...)

Collectd do a really nice job but some parts are hard to use and not really
designed for usability, the best example I have is the filter system,
Collectd comes with a really powerful filter subsystem which lets you
update/add/delete fields of the collectd "messages" or the whole messages.

Sadly this filter subsystem has one of the worst configuration interface
I have seen until now, see for yourself (and this one is a simple one):

    :apache
    <Rule "ping_server1">
      <Match "regex">
        Plugin "^ping$"
        TypeInstance "^1.2.3.4$"
      </Match>
      <Target "replace">
        TypeInstance "1.2.3.4" "server1"
      </Target>
    </Rule>

This one is pretty straight forward but all this text is just to
replace a string with another...

In another language this could become:

    :ruby
    if p.type_instance == "1.2.3.4"
      p.type_instance = "server1"
    end

Just imagine what a complex flow would look with the xml like
syntax :/

While I have some issues with collectd I am currently using it on
production servers as well as embedded systems and it works well.

### The producers

Sending your own counters to collectd is not really hard, the network
plugin of collectd use a clearly defined and simple binary format served
over UDP and many libraries exist out there for different languages to
generate those packets and send them to collectd.

### Serving graphs

The only part left is the user interface used to navigate and generate
the graphs from all these data we collected and that is where the real
problem arise... Since many existing systems want control over the
whole data collection chains you cannot easily integrate data from
somewhere else.

My quest was to find a tool doing a really simple thing (at least
I thought it was): draw graphs from rrd file and serve them to the
clients while staying nearly invisible on the server resource wise.

Do you know one ? Because I could really use some names here.

I ended up coding my own modest graph drawer but that is just a small
part of what I need. WHat I have now is a sinatra application
which uses the client itself to compute the graphs with some
javascript around the excellent jquery library: [flot](http://code.google.com/p/flot/).

Since the clients are drawing the graphs the server is really
not doing much, only extracting data from the rrd and formatting
them in json which is really nice.


## Current State

I have a working stack for now, I am not completly happy with it
but at least I have control over the parts and except for the grapher
I am just using existing application/library so I did not have
to write any code.

I am still searching for a better solutions and working on some
projects which may help but that will be for another time :)






