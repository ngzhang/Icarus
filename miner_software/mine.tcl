##
#
# Copyright (c) 2011 fpgaminer@bitcoin-mining.com
#
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
##


## TODO: Long polling.
## TODO: --verbose option for debugging issues.
## TODO: Handle multiple FPGAs at once.


package require http
package require json
package require base64

source utils.tcl
source json_rpc.tcl
source uart_comm.tcl


set total_accepted 0
set total_rejected 0

proc submit_nonce {work_data golden_nonce midstate} {
	global total_accepted
	global total_rejected
	global url
	global userpass

	#array set work $workl

	set share(data) $work_data
	set share(nonce) $golden_nonce
    set share(midstate) $midstate
	if {[submit_work $url $userpass [array get share]] == true} {
		incr total_accepted
	} else {
		incr total_rejected
	}
}
proc feed_dog {} {
    global cmd_detect
    global serial
    puts -nonewline $serial $cmd_detect
    set tmp [read_miner]
}
proc get_work_queue {} {
    array unset work
    global log_file
    global work_queue
    global miner_to
    global max_id
    global url
    global userpass
    if {$work_queue(ptr) == $work_queue(tail) } {
        puts "\[WARN\]\tWorkQueue is Empty\n"
        puts $log_file "\[WARN\]\tWorkQueue is Empty\n"
        get_work $url $userpass
        set_miner_to $miner_to
    }
    set work(data) $work_queue($work_queue(ptr),data)
    set work(midstate) $work_queue($work_queue(ptr),midstate)
    puts "\[READ\]\twork_queue(ptr)=$work_queue(ptr), work_queue(tail)=$work_queue(tail)\n"
    puts $log_file "\[READ\]\twork_queue(ptr)=$work_queue(ptr), work_queue(tail)=$work_queue(tail)\n"
    #incr work_queue(ptr) [expr ]
    if {$work_queue(ptr) == 0} {
        set work_queue(ptr) [expr $max_id - 1]
    } else {
        incr work_queue(ptr) -1
    }
    #puts "in_get_work_queue:\n$work(data)\n$work(midstate)\n"
    return [array get work]
}

#global varibles
set serial 0
set reject_num 0
set max_id 0
set miner_num 1
set timeout 6000
set to_num 0
set golden_num 0
set same_id 1
set last_ptr 0
set MAX_SAME_ID 6
set miner_to "7ffffffe"

array set work_queue ""
set work_queue(ptr) 0
set work_queue(tail) 0
set time_slice 3000

array set to_id ""
array set golden_id ""
array set golden_nonce ""

set cmd_detect     [binary format h "0"]
set cmd_set_work   [binary format h "1"]
set cmd_set_to     [binary format h "2"]
set cmd_get_status [binary format h "3"]

if {[file exists "config.tcl"]} {
    source config.tcl
}

for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    if {[string range $arg 0 0] != "-"} continue
    set opt [string range $arg 1 end]
    set value  [lindex $argv [expr $i+1]]
    if {$opt == "cn"} {
        set com_number $value
    }
    if {$opt == "ts"} {
        set time_slice $value
    }
    if {$opt == "to"} {
        set timeout $value
    }
    if {$opt == "mt"} {
        set miner_to $value
    }
    if {$opt == "cl"} {
        if {[file exists "miner.log"]} {
            file delete "miner.log"
        }
    }
    if {($opt == "h") || ($opt == "help")} {
        puts "Option Usage:\n\t-cn: set com port number\n\t-ts: set get new work frequency\nExample:\n\tIf you want to communicate with FPGA miner through com port2 and get new work every 2000 ms, you should type this:\n\ttclsh mine.tcl -cn 2 -ts 2000\n"
        exit
    }
}

set log_file [open miner.log a]
puts "\n\[NOTE\]\tFPGA miner(s) initialize...\n"
puts $log_file "\n\[NOTE\]\tFPGA miner(s) initialize...\n"

after 10000
#after 7000
fpga_init

set_miner_to $miner_to
#set_miner_to "7ffffffe"

set userpass [::base64::encode $userpass]
#set time_now [clock seconds]
set time_now [clock clicks -milliseconds]
set time_last_get_work [clock clicks -milliseconds]

set work -1

set next_id $miner_num 

set max_id [expr $miner_num * 3]

array set last_to_id ""

for {set i 0} {$i<$MAX_SAME_ID} {incr i} {
    set last_to_id($i) $i
}

while {1} {
    #puts "get miner status";
    feed_dog
    set_miner_to $miner_to
    if {$miner_num == 1} {
        puts "\[TFATAL\]\t miner_num_err\n"
        puts $log_file "\[TFATAL\]\t miner_num_err\n"
        eval exec "tclsh mine.tcl &"
        exit
    }
    if {$same_id == 1} {
        for {set i 0} {$i<$max_id} {incr i} {
            get_work $url $userpass
            feed_dog
            
        }
        set time_last_get_work [clock clicks -milliseconds]
        puts -nonewline $serial $cmd_set_work;
        set miner_num_hex [binary format h "$miner_num"];
        puts -nonewline $serial $miner_num_hex;
        for {set i 0} {$i<$miner_num} {incr i} {
            #set newwork -1;
            #while {$newwork == -1} {
                #set newwork [get_work $url $userpass]
            #}
            set newwork [get_work_queue]
            #puts "$newwork"
            array set ar_newwork $newwork
            #puts "data=$ar_newwork(data)\nmidstate=$ar_newwork(midstate)\n\n"
            set working_midstate($i) $ar_newwork(midstate)
            set working_data($i) $ar_newwork(data)
            puts "\[NOTE\]\tInit Miner(s) Work"
            push_work_to_fpga $newwork $i
        }
    }
    after 100
    set time_now [clock clicks -milliseconds]
    if {($time_now - $time_last_get_work) >= $time_slice} {
        get_work $url $userpass
        set time_last_get_work [clock clicks -milliseconds]
    }
    get_miner_status
    
    set work_num_hex [expr $golden_num + $to_num]
    if {$work_num_hex >0} {
        puts -nonewline $serial $cmd_set_work;
        #puts "total new work num = $work_num_hex, to_work = $to_num , golden_work = $golden_num"
        set work_num_hex [binary format h "$work_num_hex"]
        puts -nonewline $serial $work_num_hex;
    }
    #puts "set golden work";
    for {set i 0} {$i< $golden_num} {incr i} {
        set newwork -1;
        #while {$newwork == -1} {
        #    set newwork [get_work $url $userpass]
        #}
        set newwork [get_work_queue]
        array set ar_newwork $newwork
        set working_midstate($next_id) $ar_newwork(midstate)
        set working_data($next_id) $ar_newwork(data)
        #push_work_to_fpga $newwork $golden_id($i)
        push_work_to_fpga $newwork $next_id
        incr next_id
        if {$next_id == $max_id} {
        	set next_id 0
        }
        puts "";
        submit_nonce $working_data($golden_id($i)) $golden_nonce($i) $working_midstate($golden_id($i))
    }
    #for {set i 0} {$i<$golden_num} {incr i} {
    #}
    #puts "set golden work done";
    #puts "set to work";
    for {set i 0} {$i<$to_num} {incr i} {
        #set newwork -1;
        #while {$newwork == -1} {
        #    set newwork [get_work $url $userpass]
        #}
        set newwork [get_work_queue]
        #if {$last_to_id == $to_id($i)} {
        #    set l
        #    puts $log_file "got two same to id:$last_to_id";
        #    exit
        #}
        incr last_ptr
        if {$last_ptr == $MAX_SAME_ID} {
            set last_ptr 0
        }
        #puts "last_ptr=$last_ptr"
        set last_to_id($last_ptr) $to_id($i)
        for {set j 1} {$j<$MAX_SAME_ID} {incr j} {
            set j_1 [expr $j - 1]
            if {$last_to_id($j_1) != $last_to_id($j)} {
                break;
            }
        }
        #puts "j=$j";
        if {$j == $MAX_SAME_ID} {
            set same_id 1
            puts $log_file "\[ERROR\]\tsame_id_err";
            puts "\[ERROR\]\tsame_id_err";
            after $timeout
            eval exec "tclsh mine.tcl &"
            exit
#            for {set j 1} {$j<$MAX_SAME_ID} {incr j} {
#               puts $log_file "last_to_id $j = $last_to_id($j)";
            }

        } else {
            set same_id 0
        }
        array set ar_newwork $newwork
        set working_midstate($next_id) $ar_newwork(midstate)
        set working_data($next_id) $ar_newwork(data)
        #push_work_to_fpga $newwork $to_id($i)
        push_work_to_fpga $newwork $next_id
        incr next_id
        if {$next_id == $max_id} {
        	set next_id 0
        }       
        puts "";
    }
    if {$to_num == 0} {
        set same_id 0
    }
    #puts "set to work done";
}

puts "\n\n --- Shutting Down --- \n\n"

