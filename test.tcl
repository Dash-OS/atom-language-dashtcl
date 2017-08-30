

regexp -all -inline {(?=[^\n]*\S)[[:alpha:][:alpha:]].*\.tcl[^\n]+?} $data -> one two three
test

regexp  {^([-+]?[0-9]+)([0-9][0-9][0-9])}

regexp {^([-+]?\d+)(\d{3})$} $data -> one two


regexp  {<name>(.+)</name>(?:.*?<scope>(SYSTEM|PUBLIC)</scope>.*?<S_URI>(.+)</S_URI>(?:.*?<P_URI>(.+)</P_URI>)?)?(?:.*?<definition>(.*?)</definition>)?(?:.*?<attributes>(.*?)</attributes>)?.*?<content>(.*)</content>\s*$}


regexp {
  ^(https?:\/\/wiki.[[=alpha=]] }\ \0 \135 \072 \422 \u0905\UFAf88aaaaok \#[[:digit:]]\/)(?:.*\?redir=([0-9]+)
  |_\/edit\?N=([0-9]+)|([0-9]+))$
}

regexp {\mfoo(?!bar\M)(\w*)} $string -> restOfWord

regexp -indices {(?i)\mbadger\M} $string location

regexp -indices \
  {(?ib)\<badger\>} $string location

regexp -all {[0-7]} $string
regexp -all -inline -- {\w(\w)} " inlined "
regexp -inline -- {\w(\w)} " inlined "
regexp -all -inline {\S+} $string

regsub \
  {^([-+]?[0-9]+)([0-9][0-9][0-9])} \
  $one \
  {^([-+]?[0-9]+)\1([0-9][0-9][0-9])} \
  myVar

regsub -all -- {([^.?]*??)\cR\.c} "file.c" {cc -c & -o \1.o} ccCmd
