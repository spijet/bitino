#!/usr/bin/env bash

# Check if Ruby runtime is available:
which ruby

if [[ ! $? = "0" ]]; then
    echo "Ruby is not installed, exiting."
    exit 1
fi

# To be continued.
