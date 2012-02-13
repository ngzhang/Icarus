#!/usr/bin/env python2.7

from serial import Serial
from optparse import OptionParser
import binascii


parser = OptionParser()
parser.add_option("-s", "--serial", dest="serial_port", default="/dev/ttyUSB1", help="Serial port")
(options, args) = parser.parse_args()

ser = Serial(options.serial_port, 115200, 8)

# This will produce nonce 063c5e01 -> debug by using a bogus URL 
block = "0000000120c8222d0497a7ab44a1a2c7bf39de941c9970b1dc7cdc400000079700000000e88aabe1f353238c668d8a4df9318e614c10c474f8cdf8bc5f6397b946c33d7c4e7242c31a098ea500000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000080020000"
midstate = "33c5bf5751ec7f7e056443b5aee3800331432c83f404d9de38b94ecbf907b92d"


rdata2  = block.decode('hex')[95:63:-1]
rmid    = midstate.decode('hex')[::-1]
payload = rmid + rdata2

print("push payload to icarus")
#print(payload)
print(binascii.hexlify(payload))

ser.write(payload)
b=ser.read(4)

print("wait result:(should be: 063c5e01)")
#print(b)
print(binascii.hexlify(b))

