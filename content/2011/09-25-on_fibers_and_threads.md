---
title: "On fibers and threads"
kind: article
tags: [ruby, thread, fiber]
created_at: 2011/09/25 11:00
---


Now that ruby 1.9 is gaining more attention and more and more people are saying goodbye to ruby 1.8 to
welcome ruby 1.9.2 (don't even try 1.9.1 the latest patch release does not even work correctly...)
they rediscover the new concurrency tool 1.9 gave us: the Fiber.

So what is it all about and why can it be useful ?

## Threads

First let's start with some facts about ruby 1.9 threads:

Ruby threads are now mapped 1:1 with a native os threads, it may sounds great but not that much
because of the evil Global Interpreter Lock which guarantee only one thread will ever have the hand
so no real concurrency (in short the garbage collector was not designed to
handle multithreading so the GIL allows it to work).

The problem is that while you not gain real concurrency you still have to deal with the pain
associated with threads in any language, specifically your thread can be put to sleep anytime
and another thread will start/continue its job.

Here is an example of such behavior:


    :ruby
    require 'thread'

    MUTEX = Mutex.new

    def msg(str)
      MUTEX.synchronize { puts str }
    end

    th1 = Thread.new do
      100.times {|n| msg "[Thread 1] Tick #{n}" }
    end


    th2 = Thread.new do
      100.times {|n| msg "[Thread 2] Tick #{n}" }
    end


    th1.join
    th2.join

Just paste this code in a text file an execute it with ruby, what you will see depends on many factors but the sure
thing is that you will see tangled lines starting with Thread 1 and Thread 2 which means that none of thread did is
job in one go, here is the result on my computer (I only kept the context changes):
    
    :text
    [Thread 1] Tick 0
    [...]
    [Thread 1] Tick 67
    [Thread 2] Tick 0
    [...]
    [Thread 2] Tick 99
    [Thread 1] Tick 70
    [...]
    [Thread 1] Tick 99

This example just use the standard input (and have to use a mutex to keep both threads to write at the same time) but imagine what it can be with concurrent database queries...

I did not dug really far in ruby sources to see how threads are implemented so this explanation my
be slightly off but my understanding so far is that a ruby thread is given a fixed amount of time to do its
work, if in the given amount it is not finished the scheduler suspends it and wakeup another thread
waiting in the queue, it goes on and on until all threads are done or the program is stopped.

## Fibers

So now that we saw what Threads had to offer let's talk about their counterpart: the Fiber, first
I want to say I have no idea how fibers are implemented but it does not change the validity of the following.
    
You can think of fibers as threads without automatic scheduling, when a fiber is running nothing
else is, this is a core concept and a really important one indeed but we will talk more about this later,  
let's see an example before that:

    :ruby
    def msg(str)
      puts str
    end

    fb1 = Fiber.new do
      100.times {|n| msg "[Fiber 1] Tick #{n}" }
    end

    fb2 = Fiber.new do
      100.times {|n| msg "[Fiber 2] Tick #{n}" }
    end

    fb1.resume
    fb2.resume


What I did was just convert the thread example from before to fibers, now the result is really different
and most importantly does not depends on external factors like threads do, when executing this example
here is what you will get on any machine:


    :text
    [Fiber 1] Tick 0
    [...]
    [Fiber 1] Tick 99
    [Fiber 2] Tick 0
    [...]
    [Fiber 2] Tick 99
    
When we called resume on the first fiber it started its job and completed it, then the next line was
executed and the second fiber was started and finished its job before the program completed, no
magic, no random, just what you wrote !

Now there are things you should know about fibers, the power you have on them comes at a price:  
You need to be sure than none of your fiber will block the whole application, if you are making
a server doing heavy computation in ruby on each request you can forget fibers as only one client
will be served at once but if you are working on a server working with I/O typically the network and
one or more databases then you are good to go (with proper 1.9 drivers).

There is also some calls to avoid in the standard library, the first to come to mind is "sleep",  
here is an example of the problem with it:

    :ruby
    require 'fiber'

    fb1 = Fiber.new do
      puts "[Fiber 1] Started"
      sleep 2
      puts "[Fiber 1] Completed"
    end

    fb2 = Fiber.new do
      10.times {|n| puts "[Fiber 2] tick #{n}" }
    end

    fb1.resume
    fb2.resume
    

This program will sleep 2 seconds and then output 10 times a message, we will see in the next section how EventMachine can help us with this specific case, here is the output for this one:

    :text
    [Fiber 1] Started
    [Fiber 1] Completed
    [Fiber 2] tick 0
    [...]
    [Fiber 2] tick 9

## EventMachine

### Short introduction

  If you already know what EventMachine is you can jump to the next section.
  
When you write a standard ruby application your program once executed will run from the start to the end in a linear way, now this is where EventMachine slightly change things: when you execute an EventMachine based ruby application you are no longer in charge of the "main loop" which is now C code, instead you register for events and do action based on those events.  
A simple example would be a console program: when you are waiting for user input the application is doing nothing and that would be where the EventMachine main loop is, then when a user type something a callback in your application is called with the text, after you handled it the EventMachine main loop takes back control.
  
### How can it help us

Fibers power are best put to use in an asynchronous environment, in ruby we have the great EventMachine
but working in asynchronous mode is a real pain, here is an example from the em-http-request gem:

    :ruby
    require 'eventmachine'
    require 'em-http-request'

    EM.run do
      http = EM::HttpRequest.new('http://google.com/').get(
          :query => {'keyname' => 'value'}
        )

      http.errback { p 'Uh oh'; EM.stop }
      http.callback do
        p http.response_header.status
        p http.response_header
        p http.response

        EM.stop
      end

      puts "Done."
    end

The callback and errback block you provide will be executed respectively when a result or an error arrives and the execution will continue so "Done." will be displayed before any of the two blocks.  
We can use Threads/Fibers to transform any asynchronous code path to match the  synchronous code path we are used to work with, here is an example:

    :ruby
    require 'fiber'
    require 'eventmachine'
    require 'em-http-request'

    EM.run do
      Fiber.new do
        fb = Fiber.current
        http = EM::HttpRequest.new('http://google.com/').get(
            :query => {'keyname' => 'value'}
          )

        http.errback  { fb.resume }
        http.callback { fb.resume }

        # suspend the fiber
        Fiber.yield

        if http.error
          puts 'An error occured, damn !'
        else
          p http.response_header.status
          p http.response_header
          p http.response
        end

        EM::stop()
      end.resume
    end


See what we did ? The program execution is now linear in the fiber, this code may run a little slower
than the asynchronous code I never did any serious benchmarks but the program is so much easier to
write this way that you will see immediate gains right away !  

Note that the same can be done with threads


    :ruby
    require 'eventmachine'
    require 'em-http-request'

    EM.run do
      Thread.new do
        th = Thread.current
        http = EM::HttpRequest.new('http://google.com/').get(
            :query => {'keyname' => 'value'}
          )

        http.errback  { th.wakeup }
        http.callback { th.wakeup }

        # suspend the thread until explicit
        # wakeup
        sleep

        if http.error
          puts 'An error occured, damn !'
        else
          p http.response_header.status
          p http.response_header
          p http.response
        end

        EM::stop()
      end
    end


Fiber have another limitation though, they only have access to a limited stack size (4Kb in 1.9.2), while
you may use fibers without even noticing there is a catch: rails 3.1 which hit stable release recently can hit the boundaries of a fiber stack (see my [Rails 3.1 test application](https://github.com/schmurfy/assets_crash)) resulting in a stack overflow error and the sad thing is that there nothing you can really do about this if you are not running your own server with a modified ruby interpreter extending the stack.

A last example to show you how to do a sleep in an EventMachine fibered application:

    :ruby
    require 'fiber'
    require 'eventmachine'

    def em_sleep(n)
      fb = Fiber.current
      EM::add_timer(n){ fb.resume }
      Fiber.yield
    end

    EM::run do
      fb1 = Fiber.new do
        puts "[Fiber 1] Started"
        em_sleep 2
        puts "[Fiber 1] Completed"
        EM::stop()
      end

      fb2 = Fiber.new do
        10.times {|n| puts "[Fiber 2] tick #{n}" }
      end

      fb1.resume
      fb2.resume
    end
    
And here is the output:


    :text
    [Fiber 1] Started
    [Fiber 2] tick 0
    [...]
    [Fiber 2] tick 9
    [Fiber 1] Completed

One last thing to know about fibers is that you can only one running as I already said but this limitation is per thread so you could have more fibers running but I see little use fot this case since you get get back to the same problems you would have with threads.

## My experience in this field

I designed and implemented the core and network library of my current company's ruby servers,
these servers form a telecommunication platform and interface themselves with an heavy client
on user's computers as well as an Asterisk server, only one out of now 4/5 application servers is
a Ruby On Rails application the others are headless EventMachine servers communicating with each other.

When development started ruby 1.9 was not yet released and so I started the work on 1.8 with threads
and then later switched to 1.9 + fibers to get away from the thread concurrency hell, our productivity
raised by a great factor and the overall performances too (faster queries) but ruby 1.9 by itself
is faster than 1.8 so both implementations cannot be fairly compared.


## Interesting links

- [Threads vs Fibers resources usage](http://oldmoe.blogspot.com/2008/08/ruby-fibers-vs-ruby-threads.html)
- [em-synchrony](https://github.com/igrigorik/em-synchrony "A set of helpers to work witi fibers")
- [EventMachine](https://github.com/eventmachine/eventmachine)

