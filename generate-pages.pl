#!/usr/bin/env perl

$| = 1;

# Generic web-site generation engine.
# (c) 2000-2024, Phillip Pollard <phil@crescendo.net>

use strict;


print `rsync -av --exclude='.git/' --exclude='.DS_Store' static/ www.crescendo.net`;

# Update Jekyll and include it's output
`cd jekyll; bundle exec jekyll build; cd ..`;
print `rsync -av --exclude='.git/' --exclude='.DS_Store' jekyll/_site/ www.crescendo.net`;

exec "rsync -av --exclude='.git/' --exclude='.DS_Store' --delete www.crescendo.net/ \${MY_WEBUSER}\@\${MY_WEBHOST}:/var/www/crescendo.net/www";
