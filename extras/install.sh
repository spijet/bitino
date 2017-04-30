#!/usr/bin/env bash

function getdir() {
    SRCDIR="$(cd "$(dirname "${0}")/../" && pwd -P)"
}

# Check if Ruby runtime is available:

if ! type ruby 2>&1; then
    echo "Ruby is not installed!"
    echo "Please install Ruby, RubyGems and Bundler."
    echo "Debian users might want to install \"ruby-devel\" package too,"
    echo "since it's required for building native gem extensions."
    exit 1
elif ! type gem 2>&1; then
    echo "RubyGems is not available!"
    echo "Please install RubyGems and Bundler."
    echo "Debian users might want to install \"ruby-devel\" package too,"
    echo "since it's required for building native gem extensions."
    exit 1
elif ! type bundler 2>&1; then
    echo "Bundler is not available!"
    echo "Please install Bundler."
    echo "Debian users might want to install \"ruby-devel\" package too,"
    echo "since it's required for building native gem extensions."
    exit 1
else
    echo "Everything is looking good, proceeding."
fi




# To be continued.

#Baseballmitt Curdlemilk
#Bombadil Crucifix

getdir
