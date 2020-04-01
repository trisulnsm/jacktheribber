-- jtr_filter
-- 
-- PREFIX|PEER|ORIGIN|ASPATH
-- 
-- Only print RIB entries from a specific peer-IP
-- 
require 'jtribber'

-- usage test_file <filename> <peer_ip> 
if #arg ~= 2  then 
  print("Usage : jtr_filter   <dumpfile>  <only-this-peer-ip> ")
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


-- dump each RIB entry that passed the earlier filter
-- 
local fnclosure  = function()

	return function(mrt_record)
		if mrt_record.prefix then 
			local prefix=mrt_record.prefix

			for idx,entry in ipairs(mrt_record.rib_table) do 
				local tbl={}
				table.insert(tbl,prefix)
				table.insert(tbl,entry.peer_ip.peer_ip)
				table.insert(tbl,entry.attributes.path_attr["ORIGIN"])

				local aspath_str=table.concat(entry.attributes.path_attr["AS_PATH"].aslist,' ')
				table.insert(tbl,aspath_str)

				print(table.concat(tbl,'|'))
			end 
		end
		return true
	end
end

-- dispatch 
parse_rib( arg[1],fnclosure(),peer_filter_closure());
