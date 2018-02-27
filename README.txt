Icarus DUAL Spartan6 Development Platform is a FPGA Evaluation Board (Include 2 XILINX Spartan6 FPGAs)

"PCB"            : include PCB design project, using altium designer 10
"FPGA_project"   : include FPGA design project, using xilinx ISE13.2
"miner_software" : include miner software information
"Downloads"      : include some ready for use resource

If you want to join this project and make some changes, please e-mail me:
  ngzhang1983@msn.com

Mining software
Cgminer
Written with C, support long polling and rolling time.
Icarus in cgminer should give Utility: ~5.20/m, if the Utility is not around 5. there is something wrong.
Install cgminer in your PC:
$ git clone git://github.com/ckolivas/cgminer.git
$ cd cgminer
$ ./autogen.sh && ./configure --enable-icarus --disable-opencl --disable-adl && make
$ sudo make install
Setup with Icarus, connect Icarus to your PC. it will shows as /dev/ttyUSB0, running cgminer by:
$ cgminer -S /dev/ttyUSB0 -o http://pool.ABCPool.co -O xiangfu.0:x
If you have more Icarus connected. you may needs this little scrip file, it assume all /dev/ttyUSB* is Icarus, --api-network --api-listen is for API access for miner.php like this one:
#!/bin/sh
DEVS=`find /dev/ -type c -name "ttyUSB*"  | sed 's/^/-S/' |  sed ':a;N;$!ba;s/\n/ /g'`
cgminer $@ --api-network --api-listen -o http://pool.ABCPool.co -O xiangfu.0:x ${DEVS}

Verify FPGA core
Use this payload.py. just download it and running it like ./pyload.py -s /dev/ttyUSB0
