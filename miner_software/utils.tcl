# Reverse a hex string
proc reverseHex {hexstring} {
	set result ""
	#puts "Hex:$hexstring"
	for {set x 0} {$x < [string length $hexstring]} {incr x} {
		set piece [string range $hexstring $x [expr {$x+1}]]
		set result "${piece}${result}"
		incr x 1
	}
	
	#puts "reverseHex:$result"
	return $result
}

