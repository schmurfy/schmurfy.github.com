---
title: "Doing things differently: Erlang"
kind: article
tags: [Erlang]
created_at: 2011/06/04 14:00
---

Since I discovered RabbitMQ I kept an eye on Erlang but never looked past what is at first look an
horrible syntax.
I recently watched some presentations and read more about it to the point where I decided to take a
dive: I started reading tutorials and even bought two books, with that I was ready to start.

I was never a fan of writing useless test applications which will end up in the trash right when you
finish it, what I do instead is that I always have a folder full of what would be best described
as small tests and the way I use this is every time I am not 100% sure of how to do something or
I do not know how to do it at all I start a new file (or reopen an existing one) and start a
minimal application which is usually 5 to 10 lines.

I do this in ruby a lot and the nature of the language itself really makes it easy, see for yourself:

- create a new document in textmate (Apple + N)
- write code
- run it (Apple + R)

While it is a little harder in Erlang I still use the same process which do wonders for me.

So, aside from these tests I still needed a real project to work on, luckily I had one in stock:
I wanted to build a monitoring server similar to what collectd does but I wanted to try a different
approach and I kept this ideas for months since I had troubles deciding which language I wanted
to write it in.  
I will not speak about this application here but the project is already started and the basic
parts are working (the project is on my github account and is named collector if you want to
check it out).

The goal here is not to make another tutorial, there are enough already on the web, what I will
do now is give you an overview of erlang features and you knowns, maybe makes you want to
know more about it.

The way Erlang is built is really different from what I used until now, the main difference is obviously
the language itself but there are concepts built into Erlang which are too a great change, the syntax
is similar to prolog and knowing prolog surely helped me understand the erlang syntax faster.

We will now see some of the specific features of Erlang.

## Processes

In Erlang everything is run in what is called a process, this was really disturbing at first because
the "process" term in Erlang have really nothing to do with system processes and unlike them you can
have thousands or even millions of Erlang processes running judging by some articles/presentations I saw.  
I did not dug that too much but Erlang process seems to be code blocks distributed on a poll of threads.

You use them like you would use threads in C/Java/Ruby except they are not threads.

## Actor model

Each Erlang process has only one way to communicate with the others (that is not entirely true but
let's assume it is for now) and that is by passing a message to another process.  
That is a powerful model which is part of the language, I will speak more about it later.


## Virtual Machine

That is the first time I see what we call a virtual machine looks like an actual virtual machine !
In Erlang your can run more than one application on a given vm or even connect to it to run
commands on a live system.

Each running vm is called a node, you can connect multiple nodes to create a network which nearly acts
like a single computer making concurrent programming part of the language (both for multiple cpu cores
and multiple machines) and not something you have to specifically think about.


## Immutability

That is another disturbing things when you first try to understand the language: once a "variable"
(they are not really variable since they cannot change) is assigned a value you cannot assign
another value to it. This really looks like a limitation at first but when used with pattern
matching it is in fact really powerful.

    :erlang
    fail() ->
      A = 2,
      A = A + 4. % error !
    
    work() ->
      A = 2,
      B = A + 4. % it works

## Pattern matching

It is quite hard to wrap your mind around this one when not used to it but once you start
understanding it you can really appreciates it.

    :erlang
    connect(A) ->
      {ok, Result} = mod:do_something(A),
      Result + 2.

This piece of code looks pretty simple but what happens behind is that the function do_something
has to return a tuple (similar to a list but used to group things together, sort of a C structure
or an object) and the first element has to be "ok" (which is an atom here, they are similar to the ruby
symbols).

This means that if the function does not return a tuple or if the tuple returned does not has
ok as its first value this code will raise an error and crash.

As A C/Java/Ruby developer it is frightening when you realize that the process can crash anywhere
and our reflex would be to test if an error occurred but this is not how it works in Erlang
(C is especially horrible with the requirement to test the return
value of EACH function you call which is a huge waste of time).


## Error Handling strategy

In Erlang all your work is separated in processes, as we saw there may be a lot of them each
doing their work and optionally dying when finished, this is how you create a process in Erlang:

    :erlang
    start() ->
      spawn(func() ->
        do_something()
      end).

In the previous code the function do\_something() will be executed in a separate process from
the start function and the start function will end. But there is another way to start a process !  
If instead of using spawn you use spawn_link the process you create will be linked to the current one
and if an error occurs in the spawned process a message will be sent to this process telling it
that the process exited with the reason as an argument (which may just be that it finished its work but it may
also be that an error occured).

The way you handle errors in erlang is exactly that, instead of trying to handle everything
that could go wrong with your code you just write for the better and separate your code in
different logical parts, then you add a supervisor which is simply a process monitoring the other
processes and which will restart them on error (if you ask it to).

That is something I really do appreciate, each time I write C code it really makes me sad
having to test everything... Not only it slows me down when writing code but it create
a huge amount of code when in fact your code do not do that much.

Let's take a real world use case: You want to build a TCP Server, here is what you might write
in C  
(there is more function calls in C but that is not the point here):
    
    :c
    void start( int port )
    {
      int s, l, client;
      
      s = socket(...);
      if( s > 0 ){
        l = listen(s, 5);
        if( l != 0 ){
          client = accept(s, ...);
          if( client != -1 ){
            send(s, "Hello !");
          }
          else {
            // handle error
          }
        }
        else {
          // handle the error
        }
      }
      else {
        // handle the error
      }
    }


And in Erlang:

    :erlang
    start(Port) ->
      {ok, Listen} = gen_tcp:listen(Port, [])
      {ok, Socket} = gen_tcp:accept(Listen),
      gen_tcp:send(Socket, "Hello !").

In a real application the start function will be ran under a supervisor, if the listen of accept
call fails the process will die and will be restarted ! Coding this way is really nice, you can
concentrate on your real goal instead of keeping in mind the worst possible things that could happen.

I do not say you can completely ignore them but I found than when coding this way you can put them
aside.


## Distributed computing

The last thing I want to mention is how easy an application can be distributed across cpu cores
or even physical machines, the vm knowns how to uses all the cpu on the server running it and
you can link multiple virtual machines together to form a network of nodes (each node being
an erlang vm running on a different computer) in which a process can be spawned on any node.

Since spawn_link works from a node to another too you can have supervisors monitoring process on
multiple nodes allowing you to easily failover case where a process is spawned on node2 to replace
the one on node2 you just lost because the machine is down.




This was just was an overview of the features of this language, if you want to lean more about it
here is some resources which helped me learning it:

[Presentation from Joe Armstrong, one of Erlang creators](http://www.infoq.com/presentations/joe-armstrong-erlang-qcon08)

The two books I read after finding good reviews about them:  
[Programming Erlang written by Joe Armstrong](http://pragprog.com/titles/jaerlang/programming-erlang)  
[Erlang from O'reilly](http://oreilly.com/catalog/9780596518189)

Both books obviously have common parts but the second cover things that were only mentionned in the first one,
If you should only buy one I consider Programming Erlang.


And lastly here is a nice website with tutorials:  
[learn you some Erlang](http://learnyousomeerlang.com/content)



