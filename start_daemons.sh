#!/bin/bash

sudo memcached -d
sudo starling -d -p 15151
RAILS_ENV=production script/workling_client start

mongrel_rails start -p 3002 -e production -n 4 -d

