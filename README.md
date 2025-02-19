[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/joez/ptk)](https://hub.docker.com/r/joez/ptk/builds)

# About

My private toolkit for software development

* [gex](#gex): to manage multiple Git repos for integration purpose
* [ack][]: source code search tool with the power of [Perl][] regex
* [mojo][Mojolicious]: [Perl][] real-time web framework
* [cpanm][]: dependency free and zero configuration [Perl][] module manager
* [perltidy][]: source code formatter for [Perl][] 

# Quick start

Deploy by [Docker][]

    docker pull joez/ptk
    docker run -it --rm -v $(pwd):/work joez/ptk

Enjoy yourself for the handy tools, e.g.

    # report all commits on the current branch of the ptk project into log.xlsx
    gex report-log ptk

# Installation

Here is the prerequisites:

 * Bash shell to setup the environment
 * Network connection to install required modules

Clone it:

    git clone https://github.com/joez/ptk.git

Setup and initialize the environment:

    source ptk/envsetup

# Usage

## gex

Here is the overview of `gex`, you can find more information and examples from `gex -h`

    NAME
        gex - Manage the Git repos

    SYNOPSIS
        gex report-log [<options>] [<src>...]
        gex report-delta [<options>] <this> <that> [<src>...]
        gex report-manifest [<options>] [<src>...]

        gex forall [<options>] [<src>...]
        gex tag-manifest [<options>] <tag> [<src>...]
        gex format-patch [<options>] [<src>...]
        gex match-cherry [<options>] <this> <that> [<src>...]

        gex overlay-manifest [<options>] <this> <that> [<src>...]
        gex dump-manifest [<options>] [<src>...]

        gex find-repo [<src>...]
        gex dump-repo [<options>] [<src>...]

# Docker image

Build a [Docker][] image with the command

    docker build -t ptk ptk

Start a container and mount current directory as the workspace

    docker run -it --rm -v $(pwd):/work -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) ptk

The `USER_ID` (default 1000) and `GROUP_ID` (default 1000) are used to make the uid/gid of the container matching the current host user, so that the files created has the right ownership

**It is only needed on Linux when your current uid/gid are not 1000**

# See also

* [Perl][]
* [Docker][]
* [Mojolicious][]
* [ack][]
* [cpanm][]
* [perltidy][]

[Perl]: https://www.perl.org/
[Docker]: https://www.docker.com/
[Mojolicious]: https://mojolicious.org/
[ack]: https://beyondgrep.com/
[cpanm]: https://cpanmin.us/
[perltidy]: https://github.com/perltidy/perltidy
