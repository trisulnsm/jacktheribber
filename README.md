# jacktheribber
Jack-the-RIBber is a new high performance MRT RIB dump reader toolkit written in LuaJIT 



JT-ribber performance processing full BGP table from abour 75 peers 

````
vivek@LAT1:~/bldart/jacktheribber$ time luajit jtr_simple.lua ~/dev/bgp/ams-ix/rib.20200331.0600   > /tmp/kk

real    2m23.539s
user    2m21.726s
sys     0m1.619s

````

compared to bgpdump over the same.

````
vivek@LAT1:~/bldart/jacktheribber$ time bgpdump -m ~/dev/bgp/ams-ix/rib.20200331.0600   > /tmp/kk
2020-03-31 23:19:11 [info] logging to syslog

real    3m58.573s
user    2m14.271s
sys     1m43.940s
````

