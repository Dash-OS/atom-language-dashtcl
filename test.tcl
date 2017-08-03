proc ::utils::vendor {} {
  if { [info exists ::env(VENDOR)] } { return $::env(VENDOR) }
  if { [ file exists [ file join / remote Store App BS.exe ] ] } {
    return [ set ::env(VENDOR) "URC" ]
  } elseif { [ file exists [ file join / control4 ] ] } {
    return [ set ::env(VENDOR) "C4" ]
  } else {
    return [ set ::env(VENDOR) "UNKNOWN" ]
  }
}

incr ::one::two(three) 3
