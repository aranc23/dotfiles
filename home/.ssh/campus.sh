#! /bin/bash

if [[ `uname` == 'Darwin' ]]; then
    ifconfig -a | grep -E -q 'inet.+128\.255\.'
else
    # presumed linux
    hostname -I | grep -q '128.255.'
fi
