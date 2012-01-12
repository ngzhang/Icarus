==Miner.py manual==
-a --askrate		Seconds between getwork requests
-d --debug		Show each nonce result in hex
-m --miners		Show the nonce result remainder mod MINERS, to identify the node in a cluster
-u --url 
			URL for bitcoind or mining pool, typically http://user:password@host:8332/
			default value : http://ngzhang1983@msn.com_3:1234@pit.deepbit.net:8332/, 
-s --serial 
			Serial port, e.g. /dev/ttyS0 on unix or COM1 in Windows
			default value : com6

==Windows==
edit the 'miner.bat' to your mining worker like:
  c:\python27\python.exe miner.py -u http://ngzhang.14:1234@pool.ABCPool.co:8332  -s com6
  PAUSE

==Linux==
edit the 'miner.sh' change the 'WORKER' and 'SERIAL'
  WORKER=http://xiangfu.0:x@pool.ABCPool.co:8332 
  SERIAL=/dev/ttyUSB0
