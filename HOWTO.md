# HOWTO

First, copy files from https://github.com/ao-hime/books repo in to .book-chapters-in-markdown/ directory.

Then, run:

```bash
bundle update
./generate_chapters.rb
bundle exec jekyll build
```
