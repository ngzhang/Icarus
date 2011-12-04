# JTAG Communication Functions
# Abstracts the JTAG interface away to a few interface functions

# User API Functions
# These should be generic and be the same no matter what the underlying FPGA is.
# Use these to interact with the FPGA.
# TODO: These are designed to assume a single FPGA. Re-design to handle multiple FPGAs, assigning
# an arbitrary ID to each FPGA.


# Initialize the FPGA
proc fpga_init {} {

    global serial
    global miner_num
    global cmd_detect
    global cmd_get_status
    global timeout
    global com_number
    global log_file
    set baudrate 9600
    set parity "n" 
    set databits 8
    set stopbits 1
    #set serial [open com3: r+]
    set serial [open \\\\.\\com$com_number r+]
    #2048 > 1       + 256   + 1          + 256*(1+4)
    #       to_num  + to_id + golden_num + 256*(golden_id+golden_nonce)
    fconfigure $serial -blocking 1 -buffering none -buffersize 128 
    fconfigure $serial -mode $baudrate,$parity,$databits,$stopbits
    fconfigure $serial -encoding binary -translation binary
    fconfigure $serial -timeout $timeout
    
    puts -nonewline $serial $cmd_detect
    puts "\[NOTE\]\tDetect FPGA Miner Chain"
    puts $log_file "\[NOTE\]\tDetect FPGA Miner Chain"
    set has_miner [read_miner]
    #set has_miner [read $serial 1]
    #puts "has_miner = $has_miner"
    if {$has_miner == 0} {
    	puts stderr "\[FATAL\]\tNo FPGA Miner Found."
    	puts "\n\n\[FATAL\]\t Script Shutting Down.\n\n"
    	puts $log_file "\[FATAL\]\tNo FPGA Miner Found."
    	puts $log_file "\n\n\[FATAL\]\t Script Shutting Down.\n\n"
    	exit
    } else {
        puts "\[NOTE\]\tFpga Chain Detected";
        puts $log_file "\[NOTE\]\tFpga Chain Detected";
        #puts -nonewline $serial \x3
        #puts -nonewline $serial $cmd_get_status;
        set miner_num [get_miner_status];
        #set miner_num [read_miner];
        puts "\[NOTE\]\tTotal Miner Number = $miner_num";
        puts $log_file "\[NOTE\]\tTotal Miner Number = $miner_num";
        #set tmp [read_miner];
        #set tmp [read_miner];
    }
}

# Push new work to the FPGA
proc push_work_to_fpga {workl id} {
	global fpga_last_nonce
    global target_pack
    global serial
    global log_file
    #global cmd_set_work
	array set work $workl
    puts "\[NOTE\]\tPut work$id to Miner..."
    set data_load [string range [reverseHex $work(data)] 104 127]
    puts $log_file "data_load = $data_load"
    puts "\[NOTE\]\tdata_load = $data_load"

    set mid_state [reverseHex $work(midstate)]
    puts $log_file "mid_state = $mid_state"
    puts "\[NOTE\]\tmid_state = $mid_state"
    
    flush $log_file
    
    #set new work
    #puts -nonewline $serial $cmd_set_work
    set id_hex [binary format h "$id"]
    puts -nonewline $serial $id_hex
    for {set i 31} {$i >= 0} { incr i -1} {
        set low [expr $i*2]
        set high [expr $i*2+1]
        set tx_data [string range $mid_state $low $high]
        set tx_data [binary format H2 $tx_data]
        binary scan $tx_data H2 tx_ch
        #puts "tx_data=$tx_ch"
        puts -nonewline $serial "$tx_data"
    }
    for {set i 11} {$i >= 0} { incr i -1} {
        set low [expr $i*2]
        set high [expr $i*2+1]
        set tx_data [string range $data_load $low $high]
        set tx_data [binary format H2 $tx_data]
        puts -nonewline $serial "$tx_data"
        
        binary scan $tx_data H2 tx_ch
        #puts "tx_data=$tx_ch"
    }
	#set fpga_last_nonce [read_instance GNON]
}

proc read_miner {} {
    global serial
    global log_file
    set rdata [read $serial 1]
    if {$rdata == ""} {
        puts "\[FATAL\]\tRead Miner TimeOut, Script Restart";
        puts $log_file "\[FATAL\]\tRead Miner TimeOut, Script Restart";
        eval exec "tclsh mine.tcl &";
        exit
        #return $rdata
    }
    binary scan $rdata "c" rdata
    set rdata [expr ($rdata + 0x100)%0x100]
    #puts "get $rdata from miner";
    return $rdata
}

# Get a new result from the FPGA if one is available. Returns Golden Nonce (integer).
# If no results are available, returns -1
proc get_miner_status {} {
    global serial
    global log_file
    global to_num
    global to_id
    global max_id
    global golden_num
    global golden_id
    global golden_nonce
    global cmd_get_status
    global miner_num
    #global timeout
	#global fpga_last_nonce
	#set golden_nonce [read_instance GNON]
    #if {$golden_num != 0} {
    #    puts "delay for trigger"
    #    after 5000 
    #    puts "delay done"
    #}
    puts -nonewline $serial $cmd_get_status
    set to_num [read_miner]
    #puts "timeout fpga miner num = $to_num"
    for {set i 0} {$i < $to_num} {incr i} {
        set to_id($i) [read_miner]
        puts "\[NOTE\]\tto_id = $to_id($i)"
    }
    
    #if {$golden_num != 0} {
    #    puts "delay for trigger1"
    #    after 5000 
    #    puts "delay done"
    #}
    set golden_num   [read_miner]
    #puts "golden fpga miner num = $golden_num"
    for {set i 0} {$i < $golden_num} {incr i} {
        set golden_id($i) [read_miner]
        puts "\[NOTE\]\tgolden_id = $golden_id($i)"
        puts $log_file "golden_id = $golden_id($i)"
        set golden_nonce($i) [read_miner]
        #puts $log_file "nonce0 = $golden_nonce($i)"
        set golden_nonce($i) [expr $golden_nonce($i) + 256*[read_miner]]
        #puts $log_file "nonce1 = $golden_nonce($i)"
        set golden_nonce($i) [expr $golden_nonce($i) + 256*256*[read_miner]]
        #puts $log_file "nonce2 = $golden_nonce($i)"
        set golden_nonce($i) [expr $golden_nonce($i) + 256*256*256*[read_miner]]
        #puts $log_file "nonce3 = $golden_nonce($i)"
        if {$golden_id($i) >= $max_id} {
            puts "\[FATAL\]\tRead Miner ID ERROR:$golden_id($i), Script Restart";
            puts $log_file "\[FATAL\]\tRead Miner ID ERROR:$golden_id($i), Script Restart";
            #after $timeout
            eval exec "tclsh mine.tcl &";
            exit
        }
    }
    flush $log_file
    return $to_num;
}

proc set_miner_to {to_nonce} {
    global serial
    global cmd_set_to

    puts -nonewline $serial $cmd_set_to

    set to [binary format H2 [string range $to_nonce 6 7]]
    puts -nonewline $serial $to
    set to [binary format H2 [string range $to_nonce 4 5]]
    puts -nonewline $serial $to
    set to [binary format H2 [string range $to_nonce 2 3]]
    puts -nonewline $serial $to
    set to [binary format H2 [string range $to_nonce 0 1]]
    puts -nonewline $serial $to
}

