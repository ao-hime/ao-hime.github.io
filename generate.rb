#!/usr/bin/env bash

bundle update
./generate_chapters.rb
./generate_tags.rb
./generate_sitemap.rb
bundle exec jekyll build
