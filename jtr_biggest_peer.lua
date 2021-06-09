-- jtr_biggest_peer 
-- 
-- Prints the  biggest peer and route count
-- 
-- 
require 'jtribber'

-- usage test_file <filename> <peer_ip> 
if #arg ~= 1  then 
  print("Usage : jtr_biggest_peer    <dumpfile> ")
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
		return true
	end
end

-- dispatch 
parse_rib( arg[1],fnclosure(),peer_filter_closure());

-- Scan the peer routes table and print the peer with the most number of routes
local  maxk=nil
local  maxv=0

for k,v in pairs(peer_route_count)
do
	if tonumber(v) > maxv then
		maxv=tonumber(v)
		maxk=k
	end
end

--print(maxk..' '..maxv)
print(maxk)
