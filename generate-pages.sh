#!/usr/bin/env bash

set -e

# Copy static data into the site layout
rsync -av --exclude='.git/' --exclude='.DS_Store' static/ www.crescendo.net;

# Update Jekyll and include it's output
cd jekyll; bundle exec jekyll build; cd ..;

# Copy the rendered Jekyll output into the site layout
rsync -av --exclude='.git/' --exclude='.DS_Store' jekyll/_site/ www.crescendo.net

# Publish the combined site layout on to the server
rsync -av --exclude='.git/' --exclude='.DS_Store' --delete www.crescendo.net/ ${MY_WEBUSER}@${MY_WEBHOST}:/var/www/crescendo.net/www
