#! /bin/sh

route get default|grep -E -q 'gateway:.*(enlil.crashland|172.29.254.254)'
