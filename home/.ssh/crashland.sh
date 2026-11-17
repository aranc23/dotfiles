#! /bin/bash

if [[ `uname` == 'Darwin' ]]; then
    route get default|grep -E -q 'gateway:.*(enlil\.crashland|172\.29\.254\.254)'
else
    # presumed linux
    hostname -I | grep -q '172.29.254.'
fi
