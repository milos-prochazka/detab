
A small example, converting spaces to tabs and vice versa. Dart command line program.

=========================================================================================


Syntax: detab [options] [file ...]

options:
  -h, --help             Show this help message
  -t <n>, --tabsize <n>  Set tabulator size (default: 4)
  -d, --detab            Convert tabs to spaces (default)
  -e, --entab            Convert spaces to tabs
  -c, --crlf             Use CRLF line endings (default)
  -l, --lf               Use LF line endings

file                     File names or file name templates (wildcards * and ? allowed).
                         If no file names are specified, the program will search for files
                         in the current directory and all subdirectories.
                         If no files are found, the program will exit without error.

=========================================================================================
