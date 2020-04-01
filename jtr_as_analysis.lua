-- jtr_as_analysis 
-- 
-- Prints the following tables for an AS and BGP Peer-IP
-- 1.  Upstream ASN
-- 2.  Downstream ASN
-- 3.  IPv4 Prefixes
-- 4.  IPv6 Prefixes 
-- 
-- 
require 'jtribber'
local Tbl=require'inspect' 

-- usage test_file <filename> <peer_ip> <asn>
if #arg ~= 3  then 
  print("Usage : jtr_as_analysis   <dumpfile>  <only-this-peer-ip> <asn> ")
  return
end 

-- filter only the peer_ip 
-- this dramatically speeds up 
local peer_filter_closure=function()
	local allow_this_ip = arg[2]
	return function(peer_ip)
		return peer_ip == allow_this_ip
	end
end 


as_analysis  = {
	upstream_as = {},
	downstream_as = {},
	v4_prefixes = {},
	v6_prefixes = {},
}

-- dump each RIB entry that passed the earlier filter
-- 
local fnclosure  = function()

	local target_as = tonumber(arg[3])

	return function(mrt_record)
		if mrt_record.prefix then 
			local prefix=mrt_record.prefix

			for idx,entry in ipairs(mrt_record.rib_table) do 
				local tbl={}
				local aspath=entry.attributes.path_attr["AS_PATH"].aslist

				for i,v in ipairs(aspath) do
					if i> 1 and v==target_as then
						if i==#aspath then
							as_analysis.upstream_as[aspath[i-1]]=true	
							if prefix:find(':',1,true) then 
								as_analysis.v6_prefixes[prefix]=true	
							else
								as_analysis.v4_prefixes[prefix]=true	
							end
						else 
							as_analysis.upstream_as[aspath[i-1]]=true	
							as_analysis.downstream_as[aspath[i+1]]=true	
						end 
					end 
				end
			end 
		end

		return true
	end
end

-- dispatch 
parse_rib( arg[1],fnclosure(),peer_filter_closure());

-- output  

print(Tbl.inspect(as_analysis))
