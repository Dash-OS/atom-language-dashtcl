# Dash OS Shared Libraries
#
#   The shared libraries are the backbone of the platform.  They provide an
#   authorized application with access to the internal scripts and infrastructure
#   needed to successfully integrate with Dash OS.
#
#   Once sourced, the library will automatically load the necessary items for an
#   application to get started.  After that, applications are free to import and
#   include the various scripts and/or resources it requires.

proc % args {}

puts "Starting Dash OS"

package require fileutil
namespace eval ::Command {}

set ::starttime [clock microseconds]
set ::benchmarks [list]

proc bench { {str {}} } {
  lappend ::benchmarks [list $str [expr {  [clock microseconds] - $::starttime }]]
}

if { ! [info exists ::compiling] } {
  if { [namespace exists ::config] } { namespace delete ::config }
  namespace eval ::config {
    variable sec {}      ; # security.json
    variable api {}      ; # datastream-api.json
  }

  namespace eval ::config::dirs  {}

  namespace eval ::config::files {}

  namespace eval ::app {
    variable slug    [expr { [info exists ::app::slug] ? $::app::slug : {} }]
    variable package {}
    variable lib     {}
    variable parameters   [dict create]
  }

  namespace eval ::config::dirs {
    variable tmp            [file join [::fileutil::tempdir] dashos]
    variable dash           [file join / remote Store Common Dash]
    variable apps           [file join $dash apps]
    variable os             [file join $dash .os]
    variable packages       [file join $os packages]
    variable vfs            [file join $dash vfs os]
    variable vfs_shared     [file join $dash vfs shared]
    variable vfs_app        [file join $dash vfs app]
    variable global_storage [file join $dash Storage]
    variable app_storage    {}
    variable app {} ; # populated from $::startup::dirs::app in tempeval
  }

  namespace eval ::config::files {
    variable shared_index    [file join $::config::dirs::vfs_shared index.tcl]
    variable shared_index_ui [file join $::config::dirs::vfs_shared index_ui.tcl]
    variable index      [file join $::config::dirs::os scripts sa]
    variable lib        [file join $::config::dirs::os lib dashos.so]
    variable shared     [file join $::config::dirs::os lib dashos_shared.so]
    variable installing [file join $::config::dirs::tmp .installing]
    variable installed  [file join $::config::dirs::tmp .installcomplete]
    variable log        [file join $::config::dirs::tmp log.txt]
    variable sdk        [file join $::config::dirs::vfs sdk.tcl]
    variable sdk_ui     [file join $::config::dirs::vfs sdk_ui.tcl]
    variable ospid      [file join $::config::dirs::os var dashos.pid]
    variable pidfile    [file join $::config::dirs::os var dashos.pid]
    variable package_archive [file join $::config::dirs::dash dashos.tar.gz]
    variable build [file join $::config::dirs::dash .build]
  }
}

proc ::config::h { a } {
  if { $a eq "oshash" } {
    return eebg42at4bf1gtn2aeba1kaa4af2gdw2
  } elseif { $a eq "hash" } {
    return aebg32at4bf1gtn2aeba1kaa4af1gdw1
  }
}

proc ::app::get_package { {type dict} } {
  if { $::config::dirs::app ne {} } {
    if { [file isfile [file join $::config::dirs::vfs_app $::app::slug package.json]] } {
      # First we check if we have a package.json in the mounted vfs.  If not,
      # we will check the main directory and add that for now.
      set package [file join $::config::dirs::vfs_app $::app::slug package.json]
    } elseif { [file isfile [file join $::config::dirs::app package.tcl]] } {
      # Next we check on the package.tcl file that is included within the
      # distribution.  We will not rely on this package for long as it can
      # be tampered with.
      set package [file join $::config::dirs::app package.tcl]
    } elseif { [file isfile [file join $::config::dirs::app package.json]] } {
      set package [file join $::config::dirs::app package.json]
    }
    if { [info exists package] } {
      if { $type eq "dict" } {
        set ::app::package [json file2dict $package]
        return $::app::package
      } else {
        return [::fileutil::cat $package]
      }
    }
  }
}

proc ::app::init {} {
  # bench appinit_start
  include shared dash-app
  # This will automatically determine the current vendor
  # and source the appropriate vendor files so they meet
  # the ::vendor namespace.
  include shared vendors

  ::app::start
  # bench appinit_stop
  rename ::app::init {}
}

proc ::config::tempeval {} {
  puts tempeval

  if { [namespace exists ::startup] } {
    if { [info exists ::startup::dirs::app] } {
      set ::config::dirs::app $::startup::dirs::app
    }
    namespace delete ::startup
  }
  #
  #
  set ::config::sec [json file2dict \
    [file join $::config::dirs::vfs_shared config security.json]
  ]

  # puts $::config::sec
  # puts [file join $::config::dirs::vfs_shared config "datastream-api.json"]

  set ::config::api [json file2dict \
    [file normalize [file join $::config::dirs::vfs_shared config datastream-api.json]]
  ]

  ::app::get_package

  if { [namespace exists ::utils] } { namespace delete ::utils }

  includes shared utils general
  includes shared utils system

  include shared dash-os
  include shared datastream

  if { $::app::package ne {} } { ::app::init }

  # bench tempeval_stop
  rename ::config::tempeval {}
}

::tcl::tm::path add [file normalize [file join [file dirname [info script]] scripts]]
::tcl::tm::path add [file normalize [file join [file dirname [info script]] tcl_modules tm]]
::tcl::tm::path add [file normalize [file join [file dirname [info script]] tcl_modules task]]
::tcl::tm::path add [file normalize [file join [file dirname [info script]] tcl_modules cluster_comm]]

source [file join $::config::dirs::vfs_shared scripts utils include.tcl]

package require http_tools
package require list_tools
package require time_tools
package require ip_tools
package require ensembled
package require callback
package require json_tools
package require extend::string
package require extend::dict
package require task
package require tasks::every
package require coro
package require cmdlist
package require run
package require redelay
package require pubsub
package require oo::module
package require state
package require state::middleware::subscriptions
package require state::middleware::persist
package require state::middleware::sync
package require watcher
package require ue

state configure sync \
  -command ::dashos::sync::start

{ # one # }
# if we want to use tclparser
# load {} tclparser
# load {} Signal
# since package require does not work with it

try {
  ::config::tempeval
} on error {result options} {
  puts "Startup Error: $result"
  catch { ::onError $result $options "During Dash App Startup" }
}
