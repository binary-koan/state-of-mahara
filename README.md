# state-of-mahara

A simple utility to detect problems in the Mahara codebase. Currently this only looks for uses
of MochiKit functions, but I plan to extend it to look for things like inline <script> tags in PHP
files, functions/classes without documentation comments, excessively long lines/functions/files,
etc.

## Installation

Install Node.js, then run `npm install -g state-of-mahara`. Yes I wrote a script in JS to check a
PHP app. Deal with it.

## Usage

```
Usage: state-of-mahara [options] <path/to/mahara> [<filter/pattern>]

Options:
  -u, --update  Delete any old data for this revision and rebuild  [boolean]
  --help        Show help  [boolean]
```

Basically, point this at a Mahara installation and it will build a list of issues in the current
HEAD commit. If you run it again on the same commit, it will use the database it build last time
unless you use the `-u` flag.

The filter is converted to a regex - you can use simple glob patterns and it will match anywhere in
the path (relative to the root of your Mahara installation.

**Examples:**

`state-of-mahara -u ~/projects/mahara` - deletes any old database for whatever revision this is,
checks all the files in `~/projects/mahara`, saves the issues it finds and prints them out.

`state-of-mahara ~/projects/mahara view` - displays issues in files in any directory called 'view'.

`state-of-mahara ~/projects/mahara htdocs/js/*.js` - does exactly what you would expect (matches
JS files in the htdocs/js directory)

`state-of-mahara ~/projects/mahara htdocs/**/*.js` - also does what you would expect (matches all
JS files in the directory tree)
