[![Build Status](https://travis-ci.org/joez/ptk.svg?branch=master)](https://travis-ci.org/joez/ptk)

# About

My private toolkit

# Getting started

Prerequisites:

 * Bash shell to setup the environment
 * Network connection to install required modules

Clone (or [download](https://github.com/joez/ptk/archive/master.zip) and extract) it:

    git clone https://github.com/joez/ptk.git

Setup the environment:

    source ptk/envsetup

Enjoy yourself, e.g.

    # report all the git logs on the current branch into log.xlsx
    gex report-log ptk

    # online help
    gex -h

# Docker

Build a Docker image named `ptk`

    docker build -t ptk ptk

Start a container and mount current directory as the workspace

    docker run -it --rm -v `pwd`:/work ptk

# See also

* [Mojolicious](http://mojolicious.org/)