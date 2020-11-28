-- jtr_peerroutes 
-- 
-- Counts number of routes in MRT for each peer 
-- 
-- 
require 'jtribber'
local Tbl=require'inspect' 

-- usage test_file <filename> <peer_ip> 
if #arg ~= 1  then 
  print("Usage : jtr_peerroutes    <dumpfile> ")
  return
end 

peer_route_count = {} 

-- filter only the peer_ip 
-- this dramatically speeds up 
local peer_filter_closure=function()
	return function(peer_ip)
		local nroutes = peer_route_count[peer_ip]
		if nroutes==nil then 
			peer_route_count[peer_ip]=1
		else
			peer_route_count[peer_ip]=nroutes+1
		end
		return false
	end
end 


-- do nothing with the route .. 
-- 
local fnclosure  = function()
	return function(mrt_record)
		local prefix=mrt_record.prefix
		print(prefix) 
		return true
	end
end

-- dispatch 
parse_rib( arg[1],fnclosure(),peer_filter_closure());

-- output  
print(Tbl.inspect(peer_route_count))
