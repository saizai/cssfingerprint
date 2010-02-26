#!/bin/bash

memcached -d
starling -d -p 15151 -L log/starling.log -v -P log/starling.pid
RAILS_ENV=production script/workling_client start

mongrel_rails start -p 3002 -e production -n 4 -d

