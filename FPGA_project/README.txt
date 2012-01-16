Fold from ZTEX's miner core (http://www.ztex.de/), special thanks!

HOW TO USE:
  1. first synthesize the stuff under ./miner_core,
     then you got a NGC file, named sha256_top.ngc
  2. put this file to ./miner , then run the flow by using
     Synplify E-2011.03-SP2 as synthesizer and
     ./src/miner_top.ncd as smartguide file.

full piplined sha256 core is a very inefficient way to implement a bitcoin
mining core, it leads to a complex design for the FPGA router, so any thing
can get critical. forgive me to use such a complex flow.

Known issues (bugs to fix):
  chain mode can not support FPGA number large than 2 (2 is ok)
