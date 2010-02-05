#!/bin/bash

sudo memcached -d
sudo starling -d -p 15151
RAILS_ENV=production script/workling_client start

