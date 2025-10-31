# HOWTO

First, copy files from https://github.com/ao-hime/books repo in to .book-chapters-in-markdown/ directory.

Then, run:

```bash
bundle update
./generate_chapters.rb
./generate_tags.rb
./generate_sitemap.rb
bundle exec jekyll build
```
