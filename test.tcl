namespace eval ::ddp {
  variable url https://gateway.dashos.net/v1/ddp
  variable after_id  {}
  variable heartbeat 120000
}

variable ::ddp::template {{
  "node":  "~S:node",
  "props": "~T:@props_template"
}}

variable ::ddp::props_template {{
  "lanip":    "~S:lanip",
  "one": null
}}


::oo::class create ::ddp::beacon {

  variable AFTER_ID PROPS

  constructor {props {template {}} {onBeacon {}}} {
    set AFTER_ID {}
    if { ! [dict exists $props node] } {
      throw NODE_REQUIRED "node is a required property for ddp"
    }
    my props $props $template
    after 0 [callback my beacon]
  }

  destructor {
    after cancel $AFTER_ID
  }

  method beacon {} {
    try {
      after cancel $AFTER_ID

      set props $PROPS
      if { ! [dict exists $props @props_template] } {
        set template $::ddp::props_template
      } else {
        set template [dict get $props @props_template]
        dict unset props @props_template
      }

      dict for { k v } $props {
        dict set props $k [eval $v]
      }

      dict set props @props_template $template

      set token [ ::http::geturl $::ddp::url \
        -query   [json template $::ddp::template $props] \
        -command [list ::ddp::response {}] \
      ]

    } on error {result options} {
      ::onError $result $options "During Discovery Beacon"
      if { [info exists token] } { ::http::cleanup $token }
    } finally {
      set AFTER_ID [ after $::ddp::heartbeat [callback my beacon] ]
    }
  }

  method merge { props {template {}} } {
    set PROPS [dict merge $PROPS $props]
    if { $template ne {} } {
      if { [dict exists $PROPS @props_template] } {
        set template [json merge [dict get $PROPS @props_template] $template]]
      }
      dict set PROPS @props_template $template
    }
  }

  method props { props {template two} } {
    set PROPS $props
    if { $template ne {} } {
      dict set PROPS @props_template $template
    }
  }
}

proc ::ddp::get { {callback {}} } {
  try {
    if { $callback eq {} } {
      set token [ ::http::geturl $::ddp::url ]
      set data  [ ::http::data $token ]
      ::http::cleanup $token
      return [json get? $data]
    } else {
      set token [ ::http::geturl $::ddp::url -command [callback response $callback] ]
    }
  } on error {result options} {
    ::onError $result $options "During Discovery Request"
    if { [info exists token] } {
      ::http::cleanup $token
    }
  }
  return
}

proc ::ddp::response { callback token } {
  if { $callback ne {} } {
    set data [::http::data $token]
  }
  ::http::cleanup $token
  if { [info exists data] } {
    catch { {*}$callback [json get? $data] }
  }
}
