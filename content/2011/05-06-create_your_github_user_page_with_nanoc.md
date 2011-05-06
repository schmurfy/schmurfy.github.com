---
title: Create your Github user page with nanoc
kind: article
tags: [nanoc, nanoc3, ruby, github, blog]
created_at: 2011/05/06 15:00
---

I finally took the time to build myself a fully featured blog and start writing down things that floats
in my head both for me and for anyone it can help.<br/>
I was sure of one thing: I wanted a static blog, I do not want having to learn to use a complex
admin interface that would certainly not fit me needs and end with a fork to maintain...<br/>
Another reason is that I prefer to edit posts in my favorite text editor (that would be textmate)
than editing it online with a pale copy of a real text editor.

I was looking at github user pages for quite some time but the quick look I gave to jekyll did not convinced
me so here is an alternative way to build your github user page without using jekyll.

## What we will use

Nanoc is a powerful ruby static website generator, I already used it before for a personal documentation
repository (something like my personal knowledge database) and tested the alternatives before settling on
it so there was little to no reason to switch except if a new alternative with more features had appeared
but jekyll is certainly not that.

So nanoc it is !<br/>

This article will not teach you how to use nanoc by itself, if you are interested in it you can check:

- [The Official Website](http://nanoc.stoneship.org/)
- [The template I based mine on](https://github.com/mgutz/nanoc3_blog)
- [And obviously my template](https://github.com/schmurfy/schmurfy.github.com/tree/source)

## How github user's pages work

The user page system is really simple to use and works really well, what they did is that if you create a repository
with a special name (`<user>`.github.com) then anything pushed in the master branch will be available at the
same address, pretty neat and effective !

The master branch can either contains raw html/css/... documents or a jekyll project which will be
used to generate the html so in our case we want to push the resulting output from nanoc.

## Workspace organization

What I did is use another branch than master to host the actual nanoc application and push the
resulting html in the master branch, here is how I organized my workspace:

<pre class="language-sh">
root [ -> "source" ]
  |- content (nanoc templates)
  |- layouts (nanoc layouts)
  |- lib (ruby files extending nanoc)
  |- output [ -> "master" ]
  
</pre>

root will contains a working copy of our git repository pointing at the source branch and
output will contains a working copy of the same repository pointing at the master branch,
the tricky part here is that these two branches need to be completly separated,
we wil now see how (there is a guide on github to do this too).


## Setting up things
First we need to initialize the repository, just use your root folder for this
("$" is the prompt here):

<pre class="language-sh">
# initialize the local repository
  $ git init
# commits your files
  $ git add .
  $ git ci -m "init" 
</pre>

Now we have a master branch containing our site's source which is not yet what we
want, so we will now rename this branch and push it to the remote:

<pre class="language-sh">
# rename our master branch
  $ git br -m master source
# add your github repository as origin
  $ git add origin git@github.com:[user]/[user].github.com.git
# push to the remote repository and set the master local branch to
# track origin/master
  $ git push -u origin master
</pre>

We have a repository with only one branch: source, now we can create the master branch.<br/>
remove the output folder if it exists (rm -rf output) and do this:

<pre class="language-sh">
# fetch a working copy of your repository
  $ git clone git@github.com:[user]/[user].github.com.git output
  $ cd output
# create the isolated branch
  $ git symbolic-ref HEAD refs/heads/master
  $ rm .git/index
  $ git clean -fdx
</pre>

You should now have your master branch ready, just generate your nanoc output
(nanoc3 co in the root folder) and commit & push your files and your site should
appears shortly.

(Actually it took a second commit for me for the site to effectively appears)


One thing allowing this setup to work is that nanoc do not delete the output folder
when rebuilding the site, it justs overwrite existing files.

