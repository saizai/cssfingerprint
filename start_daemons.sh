#!/bin/bash

sudo memcached -d
sudo starling -d -p 11211
RAILS_ENV=production script/workling_client start

