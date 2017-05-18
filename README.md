# Filial

# Description

Shell file type classification tool that lets gives you a list of extensions in
a form suitable for feeding into various command line tools when you give it a
top level mime type. Current tools supported: the shell, find and grep.

This lets you do something like this:

   ls -lrt --color=auto ${~$(filial.scm zsh audio)}

# Future plans
* xdg-open/run-mailcap replacement (open and edit files)
* better support for mailcap format, encodings (gz, bz2, xz, etc.)
* support dircolors output for defining how files should be colorized by ls
