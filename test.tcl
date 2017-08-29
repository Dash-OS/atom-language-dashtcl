# {
#   "identity": "rJaMkih9x",
#   "responses": [
#     {
#       "uuid": "heartbeat",
#       "path": "/v1/system/heartbeat",
#       "identity": "rJaMkih9x",
#       "statusCode": 200,
#       "statusText": "OK",
#       "messageBody": {
#         "systemResources": {},
#         "networkInformation": {},
#         "systemStatus": {
#           "isAdopted": true,
#           "isRegistered": true,
#           "restartDetected": false
#         }
#       }
#     }
#   ]
# }
# v2 changes the response values.
proc ::datastream::response::res_heartbeat { session body } {
  if { [dict exists $body settings] } {
    set settings [dict get $body settings]
    dict pull settings heartbeatInterval ucl
    if { $ucl ne {} } {
      # We receive whether or not cloud logging is currently enabled or not.
      ::dashos::cloud_logging $ucl
    }
    if { $heartbeatInterval ne {} } {
      # TODO: Add dynamic heartbeat interval by using this value
    }
  }

  state pull myVar one two three four

  dict pull myVar one two thee four

  set test [dict create one two three four]

  if { [dict exists $body system isAdopted] } {
    # Is the system already adopted to an account?
    set isAdopted [dict get $body system isAdopted]
    # only update state if it actually exists
    dict set update isAdopted $isAdopted
  }

  if { [dict exists $body system isRegistered] } {
    set isRegistered [dict get $body system isRegistered]
    # only update state if it actually exists
    dict set update isRegistered $isRegistered
  } else { set isRegistered 0 }

  # Update the DashAuth so that it reflects the latest values
  if { [::info exists update] } { state set DashAuth $update }

  if { [info exists isAdopted] && [string is false -strict $isAdopted] } {
    # Our system has not yet been adopted - have we already registered?

    if { [string is false -strict $isRegistered] } {
      # We are not adopted and we have not registered yet
      #
      # We need to confirm that we still have an authKey available
      # to us.  If the user unadopts a system the authKey will be
      # removed, indicating that it is no longer valid.
      if { [::dashos::auth_key] ne {} } {
        {*}$session send register
      } else {
        # If we no longer have an authKey then we need to wait for a new
        # authKey to become available.
      }
    }
  }

  if { [dict exists $body locale wanIP] } {
    set wanIP [dict get $body locale wanIP]
    # only update state if it actually exists
    state set GlobalData [dict create \
      wanIP $wanIP
    ]
  } else { set isRegistered 0 }


  return
}
