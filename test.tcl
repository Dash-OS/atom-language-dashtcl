

regexp -all -inline {(?=[^\n]*\S)[[:alpha:]].*\.tcl[^\n]+?} $data -> one two three
test

regexp  {^([-+]?[0-9]+)([0-9][0-9][0-9])}

regexp {^([-+]?\d+)(\d{3})$}


regexp  {<name>(.+)</name>(?:.*?<scope>(SYSTEM|PUBLIC)</scope>.*?<S_URI>(.+)</S_URI>(?:.*?<P_URI>(.+)</P_URI>)?)?(?:.*?<definition>(.*?)</definition>)?(?:.*?<attributes>(.*?)</attributes>)?.*?<content>(.*)</content>\s*$}


regexp {^(https?:\/\/wiki.[[:alpha:]] [[:digit:]]\/)(?:.*\?redir=([0-9]+)|_\/edit\?N=([0-9]+)|([0-9]+))$}
