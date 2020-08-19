# jacktheribber

Jack-the-RIBber (JTR) is a new high performance MRT RIB dump reader toolkit written in LuaJIT 

It is used in Trisul Network Analytics ISP Edition.  The code directly reads MRT routing
information export format files (RFC6396) . At this time JTR only supports BGP RIBs via the 
TABLE_DUMP_V2 MRT Type.

## Supported formats

1. BGP RIB Dumps from Quagga  `dump bgp routes-mrt` 
2. From public routeviews dumps Eg. http://routeviews.org/ 

bq. JTR uses the excellent LUA protocol parser library from Trisul called [BITMAUL](https://github.com/trisulnsm/bitmaul). 


## Library  API 

This repository consists of a library `jtripper.lua` and several sample tools `jtr_xyz.lua` 
You can write your own library with only a few lines of code using following API

Call the `parse_rib(..)` function with the file name and two closures
	 1. function to process each MRT record 
     2. function to filter a peer  

```
require 'jtribber'   -- to include the library


local filter_closure =function () 
	return function(peer_ip) 
		-- return true to process this peer or false 
	end
end 

local process_rib = function() 
	return function(mrt_record) 
		-- do something with each MRT record 
		-- the mrt_record.prefix , mrt_record.rib_table are two fields
		-- you can use, see jtr_simple.lua

	end
end 

-- then start the loop 
parse_rib( mrt_dump_file,process_rib(),peer_filter_closure());

```

## Repository files

The following files are in this repository 

- *Libraries*
  - sweepbuf.lua - bitmaul protocol parser 
  - ip6.lua - bitmaul protocol parser ipv6 helper
- *JackTheRibber*
  - handlers.lua - BGP attributes parser (bitmaul style) 
  - rfc6396.lua - MRT file parser as per RFC 
  - jtribber.lua - the main driver library 
- *Sample Apps*
  - jtr_peerindex.lua - List all the peers found in the MRT file 
  - jtr_plain.lua - skeleton script , prints the MRT record as a LUA table
  - jtr_simple.lua - Dump all routes found from all peers 
  - jtr_filter.lua - Dump routes only from one peer IP 
  -	jtr_as_analysis.lua - Perform AS analytics, show all routes, IPv4 , IPv6 prefixes for a ASN, one peer only
  - jtr_as_analysis_allpeers.lua  - AS analytics for all peers found in the MRT RIB dump 
  - jtr_sql.lua - Dump all routes from a peer into a SQLITE3 DB 


## Performance compared to bgpdump 

JT-ribber performance processing full BGP table from abour 75 peers 


### full dumps 

````
vivek@LAT1:~/bldart/jacktheribber$ time luajit jtr_simple.lua rib.20200331.0600   > /tmp/kk

real    2m23.539s
user    2m21.726s
sys     0m1.619s

````

compared to bgpdump over the same.

````
vivek@LAT1:~/bldart/jacktheribber$ time bgpdump -m rib.20200331.0600   > /tmp/kk
2020-03-31 23:19:11 [info] logging to syslog

real    3m58.573s
user    2m14.271s
sys     1m43.940s
````

### dumps from a single peer 

This is blazing fast , a Full AS Analysis of a RIBDUMP from Chicago for a single peer *only takes 4.7 seconds*  !! 



```
rv@LAT1:~/bldart/jacktheribber$ time luajit jtr_as_analysis.lua  ~/dev/bgp/chicago/rib.20200401.0000 208.115.136.133  58898

{
  downstream_as = {
	... 
  },
  upstream_as = {
	... 
  },
  v4_prefixes = {
	... 
  },
  v6_prefixes = {}
}

real    0m4.704s
user    0m4.564s
sys     0m0.141s
```

Dont forget to check out BITMAUL - the protocol dissection tool that powers this https://github.com/trisulnsm/bitmaul
