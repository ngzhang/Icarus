# Handles all the JSON-RPC stuff
package require http
package require json
package require base64

proc do_rpc_request {url userpass request} {
	set headers [list "Authorization" "Basic $userpass"]

	set token [::http::geturl $url -query $request -headers $headers -type "application/json" -timeout 5000]

	set data [::http::data $token]
	::http::cleanup $token

	return [json::json2dict $data]
}

proc get_work {url userpass} {
	array unset work
    global log_file
    global work_queue
    global max_id
    set not_get 1
    set not_first_time 0
    while {$not_get} {
        if {$not_first_time} {
            puts "\[NOTE\]\tget work again\n"
        }
	    if [catch {
	    	set json_dict [do_rpc_request $url $userpass "{\"method\": \"getwork\", \"params\": \[\], \"id\":0}"]
	    	set json_result [dict get $json_dict result]

            if {(($work_queue(ptr) + 1) % $max_id) == $work_queue(tail)} {
                set work_queue(tail) [expr (($work_queue(tail) + 1) % $max_id)]
            }
            set work_queue(ptr) [expr (($work_queue(ptr) + 1) % $max_id)]
            puts "\[WRITE\]\twork_queue(ptr)=$work_queue(ptr), work_queue(tail)=$work_queue(tail)\n"
            puts $log_file "\[WRITE\]\twork_queue(ptr)=$work_queue(ptr), work_queue(tail)=$work_queue(tail)\n"
            set work_queue($work_queue(ptr),midstate) [dict get $json_result midstate]
	    	set work_queue($work_queue(ptr),data) [dict get $json_result data]
            set not_get 0
            #set work(difficulty) [dict get $json_result target]
	    } exc] {
	    	puts "\[WARN\]\tUnable to getwork. Reason: $exc"
            puts $log_file "\[WARN\]Unable to getwork. Reason: $exc"
            flush $log_file
            set not_first_time 1
	    }
    }
	
	return 
}

proc submit_work {url userpass workl} {
	array set work $workl
    global log_file
    global reject_num

	set nonce $work(nonce)
	set data $work(data)

	#set nonce [expr {$nonce - 132}] # No longer need to re-adjust nonce, the FPGA takes care of that.
	set nonce [format %08x $nonce]
    puts "\[NOTE\]\tgolden_nonce=$nonce"
	set hexdata1 [string range $data 0 151]
    #puts "hexdata1=$hexdata1"
	set hexdata2 [reverseHex $nonce]
    #puts "hexdata2=$hexdata2"
	set hexdata3 [string range $data 160 255]
    #puts "hexdata3=$hexdata3"
	set hexdata "${hexdata1}${hexdata2}${hexdata3}"

	#puts "Original data: $data"
	#puts "Golden data: $hexdata"

	#puts "Submitting work ..."
	
    #puts "submit data = $hexdata"
    puts $log_file "submit data = $hexdata"
	set accepted false

	if [catch {
		set json_dict [do_rpc_request $url $userpass "{\"method\": \"getwork\", \"params\": \[ \"$hexdata\" \], \"id\":1}"]
		set json_result [dict get $json_dict result]
		set json_error [dict get $json_dict error]
	
		if {($json_result == true) && ($json_error == {null})} {
			set accepted true
		}
	} exc] {
		puts "ERROR: Unable to submit share. Reason: $exc"
		set accepted false
	}

	if {$accepted == true} {
        set reject_num 0
		puts "\[NOTE\]\t$nonce accepted\n"
        puts $log_file "$nonce accepted"
	} else {
        incr reject_num
		puts "\[WARN\]\t$nonce _rejected_\n"
        #puts "\[WARN\]\tdata=$work(data)\n"
        puts "\[WARN\]\tmidstate=$work(midstate)\n"
        puts $log_file "$nonce _rejected_"
        #puts $log_file "\[WARN\]\tdata=$work(data)\n"
        puts $log_file "\[WARN\]\tmidstate=$work(midstate)\n"
        if {$reject_num >= 2} {
            puts "\[FATAL\]\tlast 2 work are all rejected, restart miner"
            puts $log_file "\[FATAL\]\tlast 2 work are all rejected, restart miner"
            eval exec "tclsh mine.tcl &"
            exit
        }
	}
    flush $log_file
	return $accepted
}

