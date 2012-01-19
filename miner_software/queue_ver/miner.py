#!/usr/bin/env python

# by teknohog

# Python wrapper for my serial port FPGA Bitcoin miners

from jsonrpc import ServiceProxy
from time import ctime, sleep, time
from serial import Serial
from threading import Thread, Event, Lock
from Queue import Queue
from optparse import OptionParser

def stats(count, starttime):
    # 2**32 hashes per share (difficulty 1)
    mhshare = 4294.967296

    s = sum(count)
    tdelta = time() - starttime
    rate = s * mhshare / tdelta

    # This is only a rough estimate of the true hash rate,
    # particularly when the number of events is low. However, since
    # the events follow a Poisson distribution, we can estimate the
    # standard deviation (sqrt(n) for n events). Thus we get some idea
    # on how rough an estimate this is.

    # s should always be positive when this function is called, but
    # checking for robustness anyway
    if s > 0:
        stddev = rate / s**0.5
    else:
        stddev = 0

    return "[%i accepted, %i failed, %.2f +/- %.2f Mhash/s]" % (count[0], count[1], rate, stddev)

class Reader(Thread):
    def __init__(self):
        Thread.__init__(self)

        self.daemon = True

        # flush the input buffer
        #ser.read(1000)

    def run(self):
        while True:
            nonce = ser.read(4)

            if len(nonce) == 4:
                # Keep this order, because writer.block will be
                # updated due to the golden event.
                submitter = Submitter(writer.block, nonce)
                submitter.start()
                if options.debug:
                    print("raise golden event\n")
                golden.set()


class Writer(Thread):
    def __init__(self):
        Thread.__init__(self)

        # Keep something sensible available while waiting for the
        # first getwork
        #self.block = "0" * 256
        #self.midstate = "0" * 64

        # This will produce nonce 063c5e01 -> debug by using a bogus URL
        self.block = "0000000120c8222d0497a7ab44a1a2c7bf39de941c9970b1dc7cdc400000079700000000e88aabe1f353238c668d8a4df9318e614c10c474f8cdf8bc5f6397b946c33d7c4e7242c31a098ea500000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000080020000"
        self.midstate = "33c5bf5751ec7f7e056443b5aee3800331432c83f404d9de38b94ecbf907b92d"

        self.daemon = True

    def run(self):
        while True:
            result =0
            #try:
            #    work = bitcoin.getwork()
            #    self.block = work['data']
            #    self.midstate = work['midstate']
            #except:
            #    print("RPC getwork error")
                # In this case, keep crunching with the old data. It will get 
                # stale at some point, but it's better than doing nothing.

            # Just a reminder of how Python slices work in reverse
            #rdata = self.block.decode('hex')[::-1]
            #rdata2 = rdata[32:64]
            work = wq.read_work_queue()
            self.block = work['data']
            self.midstate = work['midstate']
            #print("push work to miner")
            rdata2 = self.block.decode('hex')[95:63:-1]

            rmid = self.midstate.decode('hex')[::-1]
            
            payload = rmid + rdata2
            
            ser.write(payload)
            result = golden.wait(options.askrate)

            if result:
                golden.clear()
                if options.debug:
                    print("clear golden event")

class WorkQueue:
    def __init__(self, max_num):
        self.max_num = max_num+1
        self.ptr = 0
        self.ptr_tobe = 0;
        self.tail = 0
        self.in_wr = 0;
        self.work = {}
        self.work_queue = []
        for i in range(self.max_num):
            self.work_queue.append({})
    def get_from_server(self):
        get_success = 0
        while get_success != 1 :
            try:
                self.work_queue[self.ptr_tobe] = bitcoin.getwork()
                get_success = 1
            except:
                print("RPC getwork error")
    def is_full(self):
        ptr_mutex.acquire()
        full = (self.ptr + 1) % self.max_num == self.tail
        ptr_mutex.release()
        return full
    def write_work_queue(self):
        #print("update work queue")
        
        ptr_mutex.acquire()
        if (self.ptr + 1) % self.max_num == self.tail:
            if options.debug:
                print("Queue is full")
            self.tail = (self.tail + 1) % self.max_num
        self.ptr_tobe = (self.ptr + 1) % self.max_num
        #print("write0:tail=", self.tail, "ptr_tobe=", self.ptr_tobe, "ptr="+self.ptr)
        if options.debug:
            print "write0:tail=%d, ptr_tobe=%d, ptr=%d" % (self.tail, self.ptr_tobe, self.ptr)
        ptr_mutex.release()
        #self.work_queue[self.ptr] = bitcoin.getwork()
        
        write_queue_mutex.acquire()
        self.get_from_server()
        write_queue_mutex.release()
        
        ptr_mutex.acquire()
        if (self.ptr + 1) % self.max_num != self.ptr_tobe:
                self.work_queue[self.ptr] = self.work_queue[self.ptr_tobe]
        else:
            self.ptr = self.ptr_tobe
        if options.debug:
            print "write1:tail=%d, ptr_tobe=%d, ptr=%d" % (self.tail, self.ptr_tobe, self.ptr)
        #print("write1:tail="+self.tail+"ptr_tobe="+self.ptr_tobe+"ptr="+self.ptr)
        ptr_mutex.release()
        
        #print("1update work queue")
    
    def read_work_queue(self):
        ptr_mutex.acquire()
        #print("read from queue")
        if options.debug:
            print"read0:tail=%d, ptr=%d" % (self.tail, self.ptr)
        if self.ptr == self.tail:
            ptr_mutex.release()
            #print("Queue is empty")
            #print("1read from queue")
            write_queue_mutex.acquire()
            ptr_mutex.acquire()
            if self.ptr == self.tail:
                print("reader get queue")
                self.ptr_tobe = (self.ptr + 1) % self.max_num
                self.get_from_server()
                self.ptr = self.ptr_tobe
            write_queue_mutex.release()
        
        self.work = self.work_queue[self.ptr]
        
        if self.ptr == 0:
            self.ptr = self.max_num - 1
        else:
            self.ptr = self.ptr - 1
        #print("read0:tail="+self.tail+"ptr="+self.ptr)
        if options.debug:
            print"read1:tail=%d, ptr=%d" % (self.tail, self.ptr)
        
        ptr_mutex.release()
        
        return self.work
        

class GetWorkQueue(Thread):
    def __init__(self):
        Thread.__init__(self)
        self.daemon = True
        self.delay = (options.askrate>>1)+1
    def run(self):
        while True:
            if options.debug:
                print("GetWorkQueue thread")
            wq.write_work_queue()
            #if (self.ptr + 1) % self.max_num == self.tail:
            if(wq.is_full()):
                sleep(4)
                if options.debug:
                    print("queue is full, slow down request")
            else:
                if options.debug:
                    print("****\nfill the work queue at speed\n****")
            #else:
            #    sleep(2)


class Submitter(Thread):
    def __init__(self, block, nonce):
        Thread.__init__(self)

        self.block = block
        self.nonce = nonce

    def run(self):
        # This thread will be created upon every submit, as they may
        # come in sooner than the submits finish.

        print("Block found on " + ctime() + "\n")

        if stride > 0:
            n = self.nonce.encode('hex')
            print(n + " % " + str(stride) + " = " + str(int(n, 16) % stride))
        elif options.debug:
            print(self.nonce.encode('hex'))

        hrnonce = self.nonce[::-1].encode('hex')

        data = self.block[:152] + hrnonce + self.block[160:]

        try:
            result = bitcoin.getwork(data)
            print("Upstream result: " + str(result))
            print(self.nonce.encode('hex'))
        except:
            print("RPC send error")
            print(self.nonce.encode('hex'))
            # a sensible boolean for stats
            result = False

        results_queue.put(result)

class Display_stats(Thread):
    def __init__(self):
        Thread.__init__(self)

        self.count = [0, 0]
        self.starttime = time()
        self.daemon = True

        print("Miner started on " + ctime())

    def run(self):
        while True:
            result = results_queue.get()
            
            if result:
                self.count[0] += 1
            else:
                self.count[1] += 1
                
            print(stats(self.count, self.starttime))
                
            results_queue.task_done()

parser = OptionParser()

parser.add_option("-a", "--askrate", dest="askrate", default=8, help="Seconds between getwork requests")

parser.add_option("-d", "--debug", dest="debug", default=False, action="store_true", help="Show each nonce result in hex")

parser.add_option("-m", "--miners", dest="miners", default=0, help="Show the nonce result remainder mod MINERS, to identify the node in a cluster")

parser.add_option("-u", "--url", dest="url", default="http://test_fpga_btc@hotmail.com:lzhjxntswc@pit.deepbit.net:8332/", help="URL for bitcoind or mining pool, typically http://user:password@host:8332/")

parser.add_option("-s", "--serial", dest="serial_port", default="com3", help="Serial port, e.g. /dev/ttyS0 on unix or COM1 in Windows")

(options, args) = parser.parse_args()

stride = int(options.miners)

golden = Event()

ptr_mutex = Lock();
write_queue_mutex = Lock();

bitcoin = ServiceProxy(options.url)

results_queue = Queue()

ser = Serial(options.serial_port, 115200, timeout=options.askrate)

wq = WorkQueue(5)

reader = Reader()
writer = Writer()
get_work_queue = GetWorkQueue()
disp = Display_stats()

get_work_queue.start()
reader.start()
writer.start()
disp.start()

try:
    while True:
        # Threads are generally hard to interrupt. So they are left
        # running as daemons, and we do something simple here that can
        # be easily terminated to bring down the entire script.
        sleep(10000)
except KeyboardInterrupt:
    print("Terminated")

