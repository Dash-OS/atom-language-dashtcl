# =========================================================
# DO NOT CHANGE. the followings will be defined by C
# =========================================================
# varIfChanType  - 1:tcp 2:udp 3:multicast 4:broadcast 5:serial
# varIfAddress   - if varIfChanType 1~4, IP address that looks like "192.168.0.1".
#                  if varIfChanType 5, a file path that looks like "/dev/ttyS1".
# =========================================================

# =========================================================
# Define Logging Functions
# =========================================================

# GLOBAL VARIABLES - DO NOT MANUALLY OVERWRITE

# Set LOGENABLE variable if it was not already set
# This may be set by TCL Framework to enable Verbose Logging
if {[ catch { set LOGENABLE }]} 			{set LOGENABLE 0}
if {[ catch { set LOGENABLE_LEVEL }]} 		{set LOGENABLE_LEVEL 0}
if {[ catch { set LOGENABLE_INFO }]} 		{set LOGENABLE_INFO 0}
if {[ catch { set LOGENABLE_DEBUG }]} 		{set LOGENABLE_DEBUG 0}
if {[ catch { set LOGENABLE_ERROR }]} 		{set LOGENABLE_ERROR 0}
if {[ catch { set LOGENABLE_TRACE }]} 		{set LOGENABLE_TRACE 0}
if {[ catch { set LOGENABLE_TECHSUPPORT }]} {set LOGENABLE_TECHSUPPORT 0}

set LOGFILEENABLE 	0								;# Variable to track if File Logging should be enabled
set localDirectory [file dirname [info script]]		;# Variable to store the current script directory
set varIfModuleName "TCL"							;# Variable to track the Modules name (by default this will be the VFD name)


# initializeLOG
#
# 	Description:
#		LEGACY FUNCTION
#		Called by systemSDK to initialze file logging
# 	Return:
set	varIfVersionNum	"2.0.2017.0804.1"
# 		N/A
# 	Arguments:
# 		N/A
# 	Example:
#		N/A
proc initializeLOG { } {
	global localDirectory

	if { [catch {set systemLOGfile [open "$localDirectory/systemLOG.txt" "w+"]} errID] } {
		puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[initializeLOG\] couldn't open systemLOG.txt\n$errID"
		set systemLOGfile 0
	} else {
		puts $systemLOGfile "Starting system LOG"
		close $systemLOGfile
		set systemLOGfile 0
	}

	if { [catch {set clientLOGfile [open "$localDirectory/clientLOG.txt" "w+"]} errID] } {
		puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[initializeLOG\] couldn't open clientLOG.txt\n$errID"
		set clientLOGfile 0
	} else {
		puts $clientLOGfile "Starting client LOG"
		close $clientLOGfile
		set clientLOGfile 0
	}
}

# initializeLOG
#
# 	Description:
#		LEGACY FUNCTION
#		Used to enable/disable verbose logging for stdout and files
# 	Return:
# 		N/A
# 	Arguments:
#		status			->	Required	0 = Disable stdout Logging, 1 = Enable stdout Logging
#       writeToFile		->	Optional	0 = Disable file Logging, 1 = Enable file Logging
# 	Example:
#		enableLOG 1 0	->	Enables stdout logging and disabled file logging
proc enableLOG { status {writeToFile 0} } {
	global LOGENABLE
	global LOGFILEENABLE

	if {$LOGENABLE != 2} {set LOGENABLE $status}
	set LOGFILEENABLE $writeToFile
	LOG "LOGENABLE = $LOGENABLE\, LOGFILEENABLE = $LOGFILEENABLE"
}

# SetModuleName
#
# 	Description:
#		Called by systemSDK to set $::varIfModuleName with the VFD name for LOG outputs
# 	Return:
# 		N/A
# 	Arguments:
#		N/A
# 	Example:
#		N/A
proc SetModuleName {} {
	try {
		set tempList [split $::varIfScript /]
		set tempName [lindex $tempList end-1]
		set tempName [split $tempName .]
		set tempName [lindex $tempName 0]
		if {$tempName != ""} {set ::varIfModuleName $tempName}
	} on error {err trc} {
		puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[SetModuleName\] Error: $err"
		puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[SetModuleName\] Puts Trace: $trc"
	}
}

# LOG
#
# 	Description:
#		LEGACY FUNCTION
#		Prints output to stdout and/or file for debugging.
#		It is prepended with useful information such as a timestamp, module name, and the procedure that it was called from
# 	Return:
# 		N/A
# 	Arguments:
#		data	->	The text that you want to output for debugging
# 	Example:
#		LOG "This is test output"
proc LOG { data } {
	global LOGENABLE
	global LOGFILEENABLE
	global localDirectory

	if { $LOGENABLE >= 1 || $::LOGENABLE_LEVEL >=3 } {
		#Log to screen
		try {
			set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
			puts "\[[clock milliseconds]\] \[LEGACY\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $data"
		} on error {err trc} {
			puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[LOG\] Error: $err"
			puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[LOG\] Puts Trace: $trc"
		}
	}
	if { $LOGFILEENABLE >= 1 } {
		#Log to file
		if { [catch {set systemLOGfile [open "$localDirectory/systemLOG.txt" "a"]} errID] } {
			puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[LOG\] couldn't open systemLOG.txt\n$errID"
			set systemLOGfile 0
		} else {
			puts $systemLOGfile "$data"
			close $systemLOGfile
			set systemLOGfile 0
		}
	}
}

# URC::API::LOG::
#
# 	Description:
#		This is the namespace for URC Logging Functions
namespace eval URC::API::LOG {
	set InfoWrapper 		""	;# Stores the name of the Info Log wrapper function
	set CriticalWrapper 	""	;# Stores the name of the Critical Log wrapper function
	set ErrorWrapper 		""	;# Sotres the name of the Error Log wrapper function
	set DebugWrapper 		""	;# Sotres the name of the Debug Log wrapper function
	set TraceWrapper 		""	;# Sotres the name of the Trace Log wrapper function
	set TechSupportWrapper 	""	;# Sotres the name of the TechSupport Log wrapper function

	# URC::API::LOG::Enable
	#
	# 	Description:
	#		Used to enable different levels of logging and set the log wrapper functions
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		args	->	Must be a dict with aproppiate values:
	#						-info {0/1} -infoWrapper {"Name of Info Wrapper Proc"} -criticalWrapper {"Name of Critical Wrapper Proc"}
	# 	Example:
	#		URC::API::LOG::Enable -info 1 -infoWrapper "log" -criticalWrapper "critical"
	proc Enable {args} {
		# ==================================
		# Check for Enable/Disable Log Level
		# ==================================

		# Check for Info Logging
		if {[dict exists $args -info]} {
			set info [dict get $args -info]
			if {$::LOGENABLE_INFO != 2} {set ::LOGENABLE_INFO $info}
		}

		# Check for Debug Logging
		if {[dict exists $args -debug]} {
			set info [dict get $args -debug]
			if {$::LOGENABLE_DEBUG != 2} {set ::LOGENABLE_DEBUG $info}
		}

		# Check for Error Logging
		if {[dict exists $args -error]} {
			set info [dict get $args -error]
			if {$::LOGENABLE_ERROR != 2} {set ::LOGENABLE_ERROR $info}
		}

		# Check for Trace Logging
		if {[dict exists $args -trace]} {
			set info [dict get $args -trace]
			if {$::LOGENABLE_TRACE != 2} {set ::LOGENABLE_TRACE $info}
		}

		# Check for TechSupport Logging
		if {[dict exists $args -techSupport]} {
			set info [dict get $args -techSupport]
			if {$::LOGENABLE_TECHSUPPORT != 2} {set ::LOGENABLE_TECHSUPPORT $info}
		}

		# =====================================
		# Check for Log Level Wrapper Functions
		# =====================================

		# Check for a wrapper function for info level logs
		if {[dict exists $args -infoWrapper]} {
			set wrapper [dict get $args -infoWrapper]
			set ::URC::API::LOG::InfoWrapper $wrapper
		}

		# Check for a wrapper function for critical level logs
		if {[dict exists $args -criticalWrapper]} {
			set wrapper [dict get $args -criticalWrapper]
			set ::URC::API::LOG::CriticalWrapper $wrapper
		}

		# Check for a wrapper function for error level logs
		if {[dict exists $args -errorWrapper]} {
			set wrapper [dict get $args -errorWrapper]
			set ::URC::API::LOG::ErrorWrapper $wrapper
		}

		# Check for a wrapper function for debug level logs
		if {[dict exists $args -debugWrapper]} {
			set wrapper [dict get $args -debugWrapper]
			set ::URC::API::LOG::DebugWrapper $wrapper
		}

		# Check for a wrapper function for trace level logs
		if {[dict exists $args -traceWrapper]} {
			set wrapper [dict get $args -traceWrapper]
			set ::URC::API::LOG::TraceWrapper $wrapper
		}

		# Check for a wrapper function for tech support level logs
		if {[dict exists $args -techSupportWrapper]} {
			set wrapper [dict get $args -techSupportWrapper]
			set ::URC::API::LOG::TechSupportWrapper $wrapper
		}

		URC::API::LOG::Critical "Log Levels-> = TechSupport=$::LOGENABLE_TECHSUPPORT Info=$::LOGENABLE_INFO Debug=$::LOGENABLE_DEBUG Trace=$::LOGENABLE_TRACE ERROR=$::LOGENABLE_ERROR"
		URC::API::LOG::Critical "Log Wrappers-> = TechSupport=$::URC::API::LOG::TechSupportWrapper Info=$::URC::API::LOG::InfoWrapper Debug=$::URC::API::LOG::DebugWrapper Trace=$::URC::API::LOG::TraceWrapper ERROR=$::URC::API::LOG::ErrorWrapper"
	}

	# URC::API::LOG::Critical
	#
	# 	Description:
	#		Used to display persistant LOG outputs regardles of debugging status
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		txt	->	Text to be displayed in the output
	# 	Example:
	#		URC::API::LOG::Critical "The System Crashed!"
	proc Critical {txt} {
		try {
			set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
			if {$fromProc == $::URC::API::LOG::CriticalWrapper} {set fromProc [lindex [split [info level [expr [info level] - 2]]] 0]}
			puts "\[[clock milliseconds]\] \[CRITICAL\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $txt"
		} on error {err trc} {
			puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Critical\] Error: $err"
			puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Critical\] Puts Trace: $trc"
		}
	}

	# URC::API::LOG::Info
	#
	# 	Description:
	#		Used to display Info level LOG outputs
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		txt	->	Text to be displayed in the output
	# 	Example:
	#		URC::API::LOG::Info "Login Succesfull"
	proc Info {txt} {
		if { $::LOGENABLE_INFO >= 1 || $::LOGENABLE >= 1 || $::LOGENABLE_LEVEL >=3 } {
			try {
				set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
				if {$fromProc == $::URC::API::LOG::InfoWrapper} {set fromProc [lindex [split [info level [expr [info level] - 2]]] 0]}
				puts "\[[clock milliseconds]\] \[INFO\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $txt"
			} on error {err trc} {
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Info\] Error: $err"
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Info\] Puts Trace: $trc"
			}
		}
	}

	# URC::API::LOG::Error
	#
	# 	Description:
	#		Used to display Error level LOG outputs
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		txt	->	Text to be displayed in the output
	# 	Example:
	#		URC::API::LOG::Error "Invalid Account Information"
	proc Error {txt} {
		if { $::LOGENABLE_ERROR >= 1 || $::LOGENABLE >= 1 } {
			try {
				set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
				if {$fromProc == $::URC::API::LOG::ErrorWrapper} {set fromProc [lindex [split [info level [expr [info level] - 2]]] 0]}
				puts "\[[clock milliseconds]\] \[ERROR\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $txt"
			} on error {err trc} {
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Error: $err"
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Puts Trace: $trc"
			}
		}
	}

	# URC::API::LOG::Debug
	#
	# 	Description:
	#		Used to display Debug level LOG outputs
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		txt	->	Text to be displayed in the output
	# 	Example:
	#		URC::API::LOG::Debug "HTTP Response Data -> $data"
	proc Debug {txt} {
		if { $::LOGENABLE_DEBUG >= 1 || $::LOGENABLE >= 1 || $::LOGENABLE_LEVEL >=4 } {
			try {
				set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
				if {$fromProc == $::URC::API::LOG::DebugWrapper} {set fromProc [lindex [split [info level [expr [info level] - 2]]] 0]}
				puts "\[[clock milliseconds]\] \[DEBUG\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $txt"
			} on error {err trc} {
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Error: $err"
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Puts Trace: $trc"
			}
		}
	}

	# URC::API::LOG::Trace
	#
	# 	Description:
	#		Used to display Trace level LOG outputs
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		txt	->	Text to be displayed in the output
	# 	Example:
	#		URC::API::LOG::Trace "Start"
	proc Trace {txt} {
		if { $::LOGENABLE_TRACE >= 1 || $::LOGENABLE >= 1 || $::LOGENABLE_LEVEL >=5 } {
			try {
				set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
				if {$fromProc == $::URC::API::LOG::TraceWrapper} {set fromProc [lindex [split [info level [expr [info level] - 2]]] 0]}
				puts "\[[clock milliseconds]\] \[TRACE\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $txt"
			} on error {err trc} {
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Error: $err"
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Puts Trace: $trc"
			}
		}
	}

	# URC::API::LOG::TechSupport
	#
	# 	Description:
	#		Used to display TechSupport level LOG outputs
	# 	Return:
	# 		N/A
	# 	Arguments:
	#		txt	->	Text to be displayed in the output
	# 	Example:
	#		URC::API::LOG::TechSupport "System Parameter Not Set"
	proc TechSupport {txt} {
		if { $::LOGENABLE_TECHSUPPORT >= 1 || $::LOGENABLE >= 1 || $::LOGENABLE_LEVEL >=1 } {
			try {
				set fromProc [lindex [split [info level [expr [info level] - 1]]] 0]
				if {$fromProc == $::URC::API::LOG::TechSupportWrapper} {set fromProc [lindex [split [info level [expr [info level] - 2]]] 0]}
				puts "\[[clock milliseconds]\] \[TECHSUPPORT\] \[$::varIfModuleName\] \[System\] \[$fromProc\] $txt"
			} on error {err trc} {
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Error: $err"
				puts "\[[clock milliseconds]\] \[ERROR\] \[TCL\] \[::URC::API::LOG::Error\] Puts Trace: $trc"
			}
		}
	}
}

# Initialize Logging Functions
initializeLOG
SetModuleName

# =========================================================
# Require Packages
# =========================================================

URC::API::LOG::Critical "systemSDK.tcl"

package require http
package require tls
package require json

# include path to TCL packages
lappend auto_path /remote/Store/Prg/tclpkg/

# =========================================================
# External Procedure
# =========================================================
# procCtrlChannel - open/write/read/close channel
#  "open" protocol ip port [mode] [type]
#     protocol: "tcp"
#     ip      : server ip.
#     mode    : optional.
#     type    : optional.
#     return  : channel. "ch"+"pmtn" - p=t/u/m/b, m=c/s, t=s/b, n=socket number
#  "write" channel data [length]
#  "read"  channel [length]
#  "close" channel
#


# =========================================================
# Initialize source variables
# =========================================================
#
# FIXME - Set the initial value
#
# =========================================================

set varIfRet		0;
set varIfMute		0;
set varIfPower		0;	# power status
set varIfSource		"";	# input
set varIfSRMode		"";	# surround mode
set varIfNewVal     "";

set varIfDevice     "";
set varIfModule     "";
set varIfTitle      "";
set varIfArtist     "";
set varIfAlbum      "";
set varIfTrackLen   0;
set varIfTrackPos   0;
set varIfTrackNum   0;
set varIfTrackIdx   0;
set varIfPlayStatus -1;
set varIfRepeat     0;
set varIfShuffle    0;

set systemSDKSaveTheResultManual 1
set systemSDKSaveTheResultFlag 0
set systemSDKSaveTheResultBuf ""


#====================================================================================================
# tlsSocket
#
#	Desc:	A wrapper for proc tls::socket.  The original procedure does not work properly, so this
#			fix is required for now.
#	Param:	args - Contains socket metadata.
#	Return: n/a
#====================================================================================================
proc tlsSocket {args} {
	URC::API::LOG::Info "$args"
	set myArgs [list]
	set myArgs [split $args " "]
	if {[llength $myArgs] >= 3} {
		set opts [lrange $args 0 end-2]
		set host [lrange $args end-1 end-1]
		set port [lrange $args end end]
	} else {
		set opts ""
		set host [lrange $args 0 0]
		set port [lrange $args end end]
	}
	URC::API::LOG::Info "opts:$opts"
	URC::API::LOG::Info "host:$host"
	URC::API::LOG::Info "port:$port"

	::tls::socket -ssl3 false -ssl2 false -tls1 true -servername $host {*}$opts $host $port
}


# copy an array
proc ProcCopyArray {dst src} {
	upvar $src from $dst to;
	foreach {index value} [array get from *] {
		set to($index) $value;
	}
}



# sendURCLaunchStats #
#
# Save statistics to server.
#
#
package require http
package require tls
tls::init -tls1 true
::http::register https 443 tls::socket
set LaunchScriptFileName [info script]
proc sendURCLaunchStats {} {
	if {[catch {set ::varIfStatAddress}]} {
		URC::API::LOG::Info "WORKAROUND! Statistics Address not defined - Use default!"
		set ::varIfStatAddress "https://tclstat.urcmx.com/stat/"
	}
	if {[catch {set ::varIfScript}]} {
		URC::API::LOG::Info "WORKAROUND! Script filename not defined - Use default!"
		set ::varIfScript $::LaunchScriptFileName
	}
	try {
		set url $::varIfStatAddress
		append url "BSLaunch.php"
		set postvars [::http::formatQuery "MAC" $::varIfMRXMAC "Model" $::varIfBSModel "Address" $::varIfAddress "Script" $::varIfScript "Version" $::varIfVersionNum]
		set token [::http::geturl $url -timeout 5000 -query $postvars -command callbackURCStats]
	} on error {result options} {
		URC::API::LOG::Info "FAILURE: Can't collect Launch Statistics!"
	}
}

proc callbackURCStats {token} {
	::http::cleanup $token
}
after 1000 sendURCLaunchStats


proc sendErrorStats {level result {props ""}} {
	if {[catch {set ::varIfStatAddress}]} {
		URC::API::LOG::Info "WORKAROUND! Statistics Address not defined - Use default!"
		set ::varIfStatAddress "https://tclstat.urcmx.com/stat/"
	}
	if {[catch {set ::varIfScript}]} {
		URC::API::LOG::Info "WORKAROUND! Script filename not defined - Use default!"
		set ::varIfScript $::LaunchScriptFileName
	}
	try {
		set url $::varIfStatAddress
		append url "BSError.php"
		set postvars [::http::formatQuery "MAC" $::varIfMRXMAC "Model" $::varIfBSModel "Address" $::varIfAddress "Script" $::varIfScript "Version" $::varIfVersionNum "Level" $level "Result" $result "Props" $props]
		set token [::http::geturl $url -timeout 2000 -query $postvars -command callbackURCStats]
	} on error {result options} {
		URC::API::LOG::Info "FAILURE: Can't collect BS Error!"
	}
}



# connect --
#
#       Creates a connection to the socket based on the parameters given
#
# Arguments:
#		chtype	The type of connection to be made
#				1: TCP
#				2: UDP
#				3: Multicast
#				4: Broadcast
#				5: Serial
#		host	The ip address of the host server
#		port	The port to which the socket should be connected
#
# Returns:
#		socketID	The id of the socket that was just connected.
#					If the connection could not be made then a TCL_ERROR will be returned
#
# Example:
#		connect 1 192.168.42.16 6001
#
set registeredSocketID 0
set registeredSerialID 0
proc connect {chtype host port {baudrate 9600} {databits 8} {parity 0} {stopbits 1}} {
	set socketID	0
	global registeredSocketID
	global registeredSerialID

	URC::API::LOG::Info "<Tcl> ProcOpenChannel $host:$port"

	# TCP
	if {$chtype == 1} {
		if {[catch {procCtrlChannel "open" "tcp" $host $port} socketID]} {
			URC::API::LOG::Info "<Tcl> ProcOpenChannel failed $socketID"
			return 0
		}
	# UDP
	} elseif {$chtype == 2} {
		if {[catch {procCtrlChannel "open" "udp" $host $port} socketID]} {
			URC::API::LOG::Info "<Tcl> ProcOpenChannel failed $socketID"
			return 0
		}
	# Multicast
	} elseif {$chtype == 3} {
		if {[catch {procCtrlChannel "open" "mcst" $host $port} socketID]} {
			URC::API::LOG::Info "<Tcl> ProcOpenChannel failed $socketID"
			return 0
		}
	# Broadcast
	} elseif {$chtype == 4} {
		if {[catch {procCtrlChannel "open" "bcast" $host $port} socketID]} {
			URC::API::LOG::Info "<Tcl> ProcOpenChannel failed $socketID"
			return 0
		}
		# Serial
	} elseif {$chtype == 5} {
		if {[catch {procCtrlChannel "open" "serial" $host $baudrate $databits $parity $stopbits} socketID]} {
			URC::API::LOG::Info "<Tcl> ProcOpenChannel failed $socketID. SERIAL"
			return 0
		}
	} else {
		URC::API::LOG::Info "<Tcl> Unknown channel type"
		return 0
	}

	URC::API::LOG::Info "<Tcl> ProcOpenChannel succeeded $socketID"

	# Read response from channel
	if {[catch {procCtrlChannel "read" $socketID 100} varRecvLen]} {
		URC::API::LOG::Info "read error";
		return 0
	}

	#enable automatic reads
	if {$chtype == 5} {
		set registeredSerialID $socketID
	} else {
		set registeredSocketID $socketID
	}
	return $socketID
}





# read --
#
#       Checks the socket for data. It is called from with in the graphics tcl file
#		If data is present an attempt will be made to call the proc onData.
#		If the proc does not exist a error message will be displayed
#
# Arguments:
#		socketID	The ID of the socket to check
#		timeout		A timeout for how long to check for data
#
# Returns:
#		Will return an error if the socket can not be read
#
# Example:
#		read $socket1 1000
#
proc readSocket {socketID timeout} {
	global varRecvBuf
	global registeredSocketID
	global registeredSerialID

	if { $socketID != 0} {
		if {[catch {procCtrlChannel "read" $socketID $timeout} varRecvBuf]} {
			URC::API::LOG::Info "<Tcl> read failed"
			#try again
			if {[catch {procCtrlChannel "read" $socketID $timeout} varRecvBuf]} {
				URC::API::LOG::Info "<Tcl> client disconnected";
				if {[catch {onClose $socketID} errorCode]} {
					URC::API::LOG::Info "<Tcl> onClose not found"
				}
				if {$registeredSocketID == $socketID} {
					set registeredSocketID 0
				} elseif {$registeredSerialID == $socketID} {
					set registeredSerialID 0
				}
				return -code error 0;
			}
		}
		set varRecvLen [string length $varRecvBuf];
		if {$varRecvLen > 0} {
			try {
				URC::API::LOG::Info "<Tcl> -------------------------------";
				URC::API::LOG::Info "<Tcl> Received $varRecvLen bytes.";
				URC::API::LOG::Info "<Tcl> -------------------------------";
			} on error {result options} {
				URC::API::LOG::Info "Can't print incomming data: $result"
				URC::API::LOG::Info "details:\n$options"
			}

			if {$::systemSDKSaveTheResultManual == 0 && $::systemSDKSaveTheResultFlag == 1} {
				append ::systemSDKSaveTheResultBuf $varRecvBuf
			}
			try {
				onData $socketID $varRecvBuf
			} on error {result options} {
				URC::API::LOG::Info "<Tcl> onData not found or failed: $result"
				URC::API::LOG::Info "details: \n$options"
			}
		}
	}
}





# send --
#
#		Sends data out the socket given by socketID
#
# Arguments:
#		socketID	The ID of the socket to send too
#		data		The data to be sent out the socket
#
# Returns:
#		Will return an error if the socket can not be read
#
# Example:
#		send $socket1 "Test socket"
#
proc send {socketID data} {
	try {
		URC::API::LOG::Info "<Tcl> ------------------------------"
		URC::API::LOG::Info "<Tcl> Send socket: $socketID $data"
		URC::API::LOG::Info "<Tcl> ------------------------------"
	} on error {result options} {
		URC::API::LOG::Info "Can't print send data: $options"
		URC::API::LOG::Info "details: \n$options"
	}


	set dataLen [string length $data]
	if {[catch {procCtrlChannel "write" $socketID $data $dataLen}]} {
		URC::API::LOG::Info "<Tcl> send failed"
		try {
			onClose $socketID
		} on error {result options} {
			URC::API::LOG::Info "<Tcl> onClose not found pr failing: $result"
			URC::API::LOG::Info "details: \n$options"
		}
		return 0
	}
	#after 20000
}





# close --
#
#		Closes the socket
#
# Arguments:
#		socketID	The ID of the socket to close
#
# Returns:
#
#
# Example:
#		closeSocket $socket1
#
proc closeSocket {socketID} {
	global registeredSocketID
	global registeredSerialID
	if {$socketID == $registeredSocketID} {
		set registeredSocketID 0
	} elseif {$socketID == $registeredSerialID } {
		set registeredSerialID 0
	}
	procCtrlChannel "close" $socketID
}


#URC::API::LOG::Info "Starting online_closetest.tcl ..."

proc OnCloseModule { } {
	if { [ catch { onModuleClose } ] } {
	}
}

device_close OnCloseModule



#timer implementation
#proc onTimer { id } {
#	URC::API::LOG::Info "--------------"
#	URC::API::LOG::Info "--------------"
#	URC::API::LOG::Info "onTimer id=$id"
#	URC::API::LOG::Info "--------------"
#	URC::API::LOG::Info "--------------"
#}
#set timer1 [setTimer 2000]
#set timer2 [setTimer 3000]
#clearTimer $timer1
#clearTimer $timer2

set tick_var 0
set tick_time 200
set high_timer_id 0
dict set timers 0 active 0

proc clearTimer { idvalue_or_idname } {
	#**Supports both the old method of passing in the ID value and the new safer method of passing in the ID name
	#so that both the timer AND timer ID can be cleared together.**

	global timers
	global high_timer_id

	if { [ catch {expr {$idvalue_or_idname - $idvalue_or_idname}} ] == 0} {
		#URC::API::LOG::Info "clearTimer: id VALUE was passed in"; #(i.e. "4")
		set id $idvalue_or_idname
	} else {
		#URC::API::LOG::Info "clearTimer: id NAME was passed in"; #(i.e. "myTimerID")
		set id [set ::$idvalue_or_idname]
		set ::$idvalue_or_idname -1; #Clear the timer ID in the server script.
	}
	if {$id >= 0 && $id <= $high_timer_id} {
		dict set timers $id active 0
	}
}

proc setTimer { interval } {
	global tick_var
	global tick_time
	global high_timer_id
	global timers
	set done 0

	if { $interval <= 3600000 && $interval >= 100 } {
		#find next available id
		set counter 0
		dict for { id datavar } $timers {
			dict with datavar {
				if { $active == 0 } {
					set done 1
				}
			}
			if {$done == 0} {
				incr counter
			}
		}
		#URC::API::LOG::Info [ expr { [ expr { $interval / $tick_time } ] + $tick_var } ]
		dict set timers $counter active 1
		dict set timers $counter timeout [ expr { $interval / $tick_time } ]
		dict set timers $counter endtime [ expr { [ expr { $interval / $tick_time } ] + $tick_var } ]

		if {$counter >= $high_timer_id} {
			incr high_timer_id
			dict set timers $high_timer_id active 0
		}

		return $counter
	}
	return TCL_ERR
}

set timerhalfspeed 0

proc onTick {  } {
	global tick_var
	global high_timer_id
	global timers
	global registeredSocketID
	global registeredSerialID
	global timerhalfspeed
	#URC::API::LOG::Info "onTick function $tick_var"

	dict for { id datavar } $timers {
		dict with datavar {
			if {$active == 1} {
				if {$tick_var >= $endtime} {
					dict set timers $id endtime [ expr { $tick_var + $timeout } ]
					if { [ catch { onTimer $id } ] } {
						#URC::API::LOG::Info "dne"
					}
				}
			}
		}
	}
	if { $registeredSocketID > 0 && $timerhalfspeed != 0} {
		readSocket $registeredSocketID 100
		set timerhalfspeed 0
	} elseif { $registeredSerialID > 0 && $timerhalfspeed != 0} {
		readSocket $registeredSerialID 100
		set timerhalfspeed 0
	} else {
		set timerhalfspeed 1
	}
	incr tick_var
}

device_tick $tick_time onTick


proc saveTheResult {data} {
	if {$::systemSDKSaveTheResultFlag} {
		append ::systemSDKSaveTheResultBuf $data
	}
}

proc convert.hex.to.string hex {
    foreach c [split $hex {}] {
        if {![string is xdigit $c]} {
            return $hex
        }
    }
    set res [binary format H* $hex]
	return $res
}

namespace eval localTime {
	proc getLocalTime {{ip 127.0.0.1}} {
		return [::URC::API::GetLocalTime $ip]
	}
}

namespace eval URC::API {
	set Hardware -1

	proc SetHardwareType {} {
		if {[string match "*MRX*" $::varIfBSModel] == 1 || [string match "*CP*" $::varIfBSModel] == 1} {
			set ::URC::API::Hardware "TC"
		} elseif {[string match "*hcm*" $::varIfBSModel] == 1} {
			set ::URC::API::Hardware "HC"
		} else {
			set ::URC::API::Hardware -1
		}
	}

	proc GetSunInfo {} {
		set retVal -1

		if {$::URC::API::Hardware == "TC"} {
			set retVal [::URC::API::TC::GetSunInfo]
		} elseif {$::URC::API::Hardware == "HC"} {
			set retVal [::URC::API::HC::GetSunInfo]
		} else {
			URC::API::LOG::Info "Unsupported Hardware"
		}

		return $retVal
	}

	proc GetLocalTime {{ip 127.0.0.1}} {
		set retVal -1

		if {$::URC::API::Hardware == "TC"} {
			set retVal [::URC::API::TC::GetLocalTime]
		} elseif {$::URC::API::Hardware == "HC"} {
			set retVal [::URC::API::HC::GetLocalTime $ip]
		} else {
			URC::API::LOG::Info "Unsupported Hardware"
			set retVal [clock seconds]
		}

		return $retVal
	}
}

namespace eval URC::API::TC {
	proc GetLocalTime {} {
		try {
			set local_Time [procCtrlChannel "event_command" "get_time_info"]
		} on error {err trc} {
			URC::API::LOG::Info  "Error:$err"
			URC::API::LOG::Info  "Trace:$trc"
			set local_Time [clock seconds]
		}
		return $local_Time
	}

	proc GetSunInfo {} {
		try {
			set suninfo [procCtrlChannel event get_sunrise_sunset_info]
			if {[dict exists $suninfo sunrise] && [dict exists $suninfo sunset]} {
				# Get time offset
				set loctimestamp [::URC::API::GetLocalTime]
				set UTCtimestamp [clock seconds]
				set offset [expr { $UTCtimestamp - $loctimestamp }]

				#get timestamp for sunrise
				set timestamp [clock scan [dict get $suninfo "sunrise"]]
				dict set suninfo "sunrise timestamp" $timestamp

				# Get time & timestamp for UTC sunrise
				set timestamp [incr timestamp $offset]
				set time [clock format $timestamp -format "%H:%M:%S"]
				dict set suninfo "sunrise UTC timestamp" $timestamp
				dict set suninfo "sunrise UTC" $time

				# Get timestamp for sunset
				set timestamp [clock scan [dict get $suninfo "sunset"]]
				dict set suninfo "sunset timestamp" $timestamp

				# Get time & timestamp for UTC sunset
				set timestamp [incr timestamp $offset]
				set time [clock format $timestamp -format "%H:%M:%S"]
				dict set suninfo "sunset UTC timestamp" $timestamp
				dict set suninfo "sunset UTC" $time

				return $suninfo
			} else {
				URC::API::LOG::Info  "Bad return from Firmware"
				URC::API::LOG::Info  "suninfo -> $suninfo"
				return -1
			}
		} on error {err trc} {
			URC::API::LOG::Info  "Error: $err"
			URC::API::LOG::Info  "Trace: $trc"
			return -1
		}
	}
}

namespace eval URC::API::HC {
	proc GetSunInfo {} {
		URC::API::LOG::Info  "Not yet implemented"
		return -1
	}

	proc GetLocalTime {ip} {
		try {
			set local_Time [::URC::API::HC::LocalTime::sendreq $ip]
		} on error {err trc} {
			URC::API::LOG::Info  "Error:$err"
			URC::API::LOG::Info  "Trace:$trc"
			set local_Time [clock seconds]
		}
		return $local_Time
	}
}

namespace eval URC::API::HC::LocalTime {
	proc sendreq {{ip 127.0.0.1}} {
		set token [::http::geturl "http://${ip}/rest/tzinfo"]
		if {[::http::ncode $token] == 200} {
			set ret [parsereq [::http::data $token]]
			::http::cleanup $token
			set ret [expr {$ret * 60}]
			return [expr {[clock seconds] - $ret}]
		}

		URC::API::LOG::Info "<Tcl> getTimeInfo error... Using UTC"
		return [clock seconds]
	}

	proc parsereq {data} {
		set jsondata [::json::json2dict $data]
		if {[dict get $jsondata result] eq "ok" } {
			if {[dict get $jsondata dst_auto] == 1} {
				#check if daylight savings
				set daylightSavings [evalDaylightSavings [dict get $jsondata s_time] [dict get $jsondata d_time] [dict get $jsondata bias] [ dict get $jsondata d_bias ]]
				if {$daylightSavings == 1} {
					return [expr { [ dict get $jsondata bias ] + [ dict get $jsondata d_bias ] }]
				} else {
					return [ dict get $jsondata bias ]
				}
			} else {
				return [dict get $jsondata bias]
			}
		} else {
			URC::API::LOG::Info "<Tcl> getTimeInfo error... Using UTC"
			return 0
		}

		URC::API::LOG::Info "<Tcl> getTimeInfo error... Using UTC"
		return 0
	}


	proc evalDaylightSavings {standarDate daylightDate bias d_bias} {
		set arr [split $standarDate "/"]
		set S_datearr [split [lindex $arr 0] "."]
		set S_timearr [split [lindex $arr 1] ":"]
		set S_month [string range [lindex $S_datearr 0] 1 end]
		set S_week [lindex $S_datearr 1]
		set S_dayOfWeek [lindex $S_datearr 2]
		set S_switchDay ""


		set arr [split $daylightDate "/"]
		set D_datearr [split [lindex $arr 0] "."]
		set D_timearr [split [lindex $arr 1] ":"]
		set D_month [string range [lindex $D_datearr 0] 1 end]
		set D_week [lindex $D_datearr 1]
		set D_dayOfWeek [lindex $D_datearr 2]
		set D_switchDay ""

		set timestamp [clock seconds]
		set timestamp [expr {$timestamp - (60 * $bias)}]

		set C_month [clock format $timestamp -format "%m"]
		set C_month [string trimleft $C_month 0]
		set C_dayOfWeek [expr {[clock format $timestamp -format "%u"] % 7}]
		set C_dayOfMonth [clock format $timestamp -format "%e"]


		if { $C_month > $S_month || $C_month < $D_month } {
			# This month is not using daylight savings
			return 0
		} elseif {$C_month < $S_month && $C_month > $D_month } {
			# This month is using daylight savings
			return 1
		} elseif {$C_month == $S_month} {
			# complicated this is a month where the change occurs
			# find all days of the month that is the correct weekday
			set SwDay [expr {$C_dayOfWeek - $S_dayOfWeek}]
			set SwDay [expr {$C_dayOfMonth - $SwDay}]
			set SwDay [expr {$SwDay - ( 7 * int($SwDay / 7) )}]
			if {$SwDay <= 0} {
				incr SwDay 7
			}
			lappend S_switchDay $SwDay; #first day
			while 1 {
				incr SwDay 7
				set daysOfMonth 31
				# limit number of days for certain months
				switch $C_month {
					"2" {
						set daysOfMonth 28
					}
					"4" -
					"6" -
					"9" -
					"11" {
						set daysOfMonth 30
					}
					default {
						set daysOfMonth 31
					}
				}

				if { $SwDay <= $daysOfMonth } {
					lappend S_switchDay $SwDay
				} else {
					break
				}
			}

			# find the date for the specified change week
			set compDay 0
			if {$S_week >= 5} {
				# 5 indicates last week of the month
				set lenSwitchDay [llength $S_switchDay]
				if {$lenSwitchDay > 0} {
					set compDay [lindex $S_switchDay [expr {$lenSwitchDay - 1}]]
				} else {
					set compDay 0
				}
			} else {
				# use the nth week of the month
				if {$S_week > 0} {
					incr S_week -1
				}
				set compDay [lindex $S_switchDay $S_week]
			}

			#compare the day of the month
			if { $C_dayOfMonth <  $compDay } {
				return 1
			} elseif { $C_dayOfMonth > $compDay} {
				return 0
			} else {
				# same day as daylight savings shift
				# Check the time
				set timestamp [expr {$timestamp - ( 60 * $d_bias ) } ]
				set C_hour [clock format $timestamp -format "%k"]
				set S_hour [lindex $S_timearr 0]
				set S_hour [string trimleft $S_hour 0]
				if {$S_hour == ""} {
					set $S_hour 0
				}

				if {$C_hour < $S_hour} {
					return 1
				} else {
					return 0
				}
			}
		} elseif {$C_month == $D_month} {
			# complicated this is a month where the change occurs
			# find all days of the month that is the correct weekday
			set SwDay [expr {$C_dayOfWeek - $D_dayOfWeek}]
			set SwDay [expr {$C_dayOfMonth - $SwDay}]
			set SwDay [expr {$SwDay - ( 7 * int($SwDay / 7) )}]
			if {$SwDay <= 0} {
				incr SwDay 7
			}
			lappend D_switchDay $SwDay; #first day
			while 1 {
				incr SwDay 7
				set daysOfMonth 31
				# limit number of days for certain months
				switch $C_month {
					"2" {
						set daysOfMonth 28
					}
					"4" -
					"6" -
					"9" -
					"11" {
						set daysOfMonth 30
					}
					default {
						set daysOfMonth 31
					}
				}

				if { $SwDay <= $daysOfMonth } {
					lappend D_switchDay $SwDay
				} else {
					break
				}
			}

			# find the date for the specified change week
			set compDay 0
			if {$D_week >= 5} {
				# 5 indicates last week of the month
				set lenSwitchDay [llength $D_switchDay]
				if {$lenSwitchDay > 0} {
					set compDay [lindex $D_switchDay [expr {$lenSwitchDay - 1}]]
				} else {
					set compDay 0
				}
			} else {
				# use the nth week of the month
				if {$D_week > 0} {
					incr D_week -1
				}
				set compDay [lindex $D_switchDay $D_week]
			}

			#compare the day of the month
			if { $C_dayOfMonth >  $compDay } {
				return 1
			} elseif { $C_dayOfMonth < $compDay} {
				return 0
			} else {
				# same day as daylight savings shift
				# Check the time
				set C_hour [clock format $timestamp -format "%k"]
				set D_hour [lindex $D_timearr 0]
				set D_hour [string trimleft $D_hour 0]
				if {$D_hour == ""} {
					set $D_hour 0
				}

				if {$C_hour < $D_hour} {
					return 0
				} else {
					return 1
				}
			}
		}

		return 0

	}
}

catch {::URC::API::SetHardwareType}


# =========================================================
# OnDevCmd
#   - Supports sending parameter to server for TCP Macro
#   - this procedure called by C.
#
#   - returned format: 1 on success or 0 on failure
# =========================================================
#
# FIXME -
#
# =========================================================
proc OnDevCmd { param_len param {cmd 0} {zone 0} {type 0} {address 0} {port_or_baud 0} {databits 0} {parity 0} {stopbits 0} {receive_option 0} {wait_time 0} } {
	global registeredSocketID
	global registeredSerialID
	URC::API::LOG::Info "OnDevCmd...";
	URC::API::LOG::Info "this procedure is used for TCP Macro";

	URC::API::LOG::Info "param_len = $param_len, param=<$param>";
	URC::API::LOG::Info "cmd = $cmd"

	URC::API::LOG::Info "======================================";
	URC::API::LOG::Info "zone = $zone";
	URC::API::LOG::Info "type = $type";
	URC::API::LOG::Info "address = <$address>";
	URC::API::LOG::Info "port/baud = $port_or_baud";
	URC::API::LOG::Info "databits = $databits";
	URC::API::LOG::Info "parity = $parity";
	URC::API::LOG::Info "stopbits = $stopbits";
	URC::API::LOG::Info "receive_opt = $receive_option";
	URC::API::LOG::Info "wait_time = $wait_time";
	URC::API::LOG::Info "======================================";

	set zone [expr { $zone + 1 } ]
	#
	# TODO
	#

	if {$cmd == 0} {

		#convert HomeSet 1-way commands to binary
		if {[string match "*hcm-c1*" $::varIfBSModel]} {
			set param [convert.hex.to.string $param]
		}

		if {$type == 3} {
			# try to call send override
			try {
				sendOverride $registeredSerialID $param $receive_option $wait_time
			} on error {result options} {
				URC::API::LOG::Info "Advanced version of sendOverride failed. Trying simplified."
				URC::API::LOG::Info "$result \ndetails: \n$options"

				try {
					sendOverride $registeredSerialID $param
				} on error {result options} {
					URC::API::LOG::Info "Simplified version of sendOverride failed. Using direct send!"
					URC::API::LOG::Info "$result \ndetails: \n$options"

					set ::systemSDKSaveTheResultManual 0
					# Send the given param to AVR. Write request to channel
					if {$registeredSerialID == 0} {
						# connect to serial
						try {
						set registeredSerialID [connect 5 $address 0 $port_or_baud $databits $parity $stopbits]
						} on error {result options} {
							URC::API::LOG::Info "Required connection to serial port failed: $result"
							URC::API::LOG::Info "details: \n$options"
							return 0
						}
					}
					try {
						send $registeredSerialID $param
					} on error {result options} {
						URC::API::LOG::Info "Cannot write to channel";
						return 0
					}
				}
			}
		} else {
			# try to call send override
			try {
				sendOverride $registeredSocketID $param $receive_option $wait_time
			} on error {result options} {
				URC::API::LOG::Info "Advanced version of sendOverride failed. Trying simplified."
				URC::API::LOG::Info "$result \ndetails: \n$options"

				try {
					sendOverride $registeredSocketID $param
				} on error {result options} {
					URC::API::LOG::Info "Simplified version of sendOverride failed. Using direct send!"
					URC::API::LOG::Info "$result \ndetails: \n$options"

					set ::systemSDKSaveTheResultManual 0
					if {$registeredSocketID == 0} {
						# connect to TCP socket
						try {
							set registeredSocketID [connect $type $address $port_or_baud]
						} on error {result options} {
							URC::API::LOG::Info "Required connection to serial port failed: $result"
							URC::API::LOG::Info "details: \n$options"
							return 0
						}
					}
					# Send the given param to AVR. Write request to channel
					try {
						send $registeredSocketID $param
					} on error {result options} {
						URC::API::LOG::Info "Cannot write to channel";
						return 0;
					}
				}
			}
		}
		if { $receive_option == 1 } {
			URC::API::LOG::Info "Start receive...";
			# To do...
			# clear receive buffer...
			set ::systemSDKSaveTheResultBuf ""
			set ::systemSDKSaveTheResultFlag 1
		}
	} elseif {$cmd == 2} {
		URC::API::LOG::Info "this procedure is used for Save_the_result...";
		# To do...
		# send received buffer
		set ::systemSDKSaveTheResultFlag 0
		set length [string bytelength $::systemSDKSaveTheResultBuf]
		return "$length\t$::systemSDKSaveTheResultBuf"
	} elseif {$cmd == 3} {
		URC::API::LOG::Info "this procedure is used for TRF-ZW1 1-way command"
		if {[catch {TRFZWCommand $param }]} {
			URC::API::LOG::Info "\"TRFZWCommand param\" expected but not found"
		}
	} elseif {$cmd == 4} {
		if { [catch {set returndata [ExecuteMacroQuery $param] } ] } {
			return "0\t"
		}
		set returnlength [string bytelength $returndata]
		return "$returnlength\t$returndata"
	} elseif {$cmd == 5} {
		URC::API::LOG::Info "SIP relay"
		try {
			return [SIPrelay $param $address $port_or_baud]
		} on error {arg1 arg2} {
			URC::API::LOG::Info "SIP relay not implemented or procedure failed"
		}
	} elseif {$cmd == 8} {
		URC::API::LOG::Info "MCS Status Check"
		try {
			return [ModuleHealthCheck]
		} on error {arg1 arg2} {
			URC::API::LOG::Info "ModuleHealthCheck procedure not implemented or failed, returning 1"
			return 1
		}
	} elseif {$cmd == 31} {
		LOG "Receiving Unified UI CMD"
		set retData -1
		try {
			set retData [::URC::API::Unified::UI::CMD $type $param]
		} on error {err trc} {
			LOG "Error: $err"
			LOG "Trace: $trc"
		}
		return $retData
	} else {
		URC::API::LOG::Info "this procedure is used for Volume feedback command";
		if { $param eq "SETVOL"} {
			catch { VolumePopupSetVolume $zone [expr {$param_len / 10.0} ] }
		}
		set localVarIfMin [expr {int($::varIfMin * 10)}]
		set localVarIfMax [expr {int($::varIfMax * 10)}]
		set localVarIfVol [expr {int($::g_arrStatus($zone.dwVolume) * 10)}]

		set retbuf [format "%d\t%d\t%d\t%d\t%s" $localVarIfVol $localVarIfMin $localVarIfMax $::g_arrStatus($zone.dwMute) $::g_arrStatus($zone.dwInput)];
		return $retbuf;
	}

	return 0;
}

proc module_proc {value} {
        return [rui_module $value]
}



proc stacktrace {} {
    set stack "Stack trace:\n"
    for {set i 1} {$i < [info level]} {incr i} {
        set lvl [info level -$i]
        set pname [lindex $lvl 0]
        append stack [string repeat " " $i]$pname
        foreach value [lrange $lvl 1 end] arg [info args $pname] {
            if {$value eq ""} {
                info default $pname $arg value
            }
            append stack " $arg='$value'"
        }
        append stack \n
    }
    return $stack
}

proc bgerror {message} {
	global errorInfo
	URC::API::LOG::Critical "======ERROR======"
	URC::API::LOG::Critical ""
	URC::API::LOG::Critical "The Program captured an error."
	URC::API::LOG::Critical "$message"
	URC::API::LOG::Info "stack trace:"
	URC::API::LOG::Info "$errorInfo"
	URC::API::LOG::Critical ""
	URC::API::LOG::Critical "================="

	sendErrorStats 0 $message $errorInfo
}

# getTCLStorage
#
# Description:
#       A Function to set the Path to a Common file location used by TCL modules
#
proc getTCLStorage {} {
	set path ""
	if {[info exists ::env(TCLCOMMONPATH)]} {
		set path "$::env(TCLCOMMONPATH)"
	} else {
		set path "/remote/Store/Common/"
		if {![file isdirectory $path]} {file mkdir $path}
	}
	return $path
}

# =========================================================
# Register procedure for TCP Macro
# =========================================================
device_cmd OnDevCmd
