#!/usr/bin/bash

lxc list --format csv --columns n | grep fuseki3 | \
    parallel -j 1 lxc file push machines/config/fuseki-config.ttl {}/home/ubuntu/ 
