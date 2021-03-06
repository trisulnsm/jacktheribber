--
-- PREFIX|PEER|ORIGIN|ASPATH
-- 
require 'jtribber'

-- usage test_file <filename> 
if #arg ~= 1 then 
  print("Usage : jtr_simple  <dumpfile> ")
  return
end 

-- 
-- Print each RIB Entry , Pipe Separated
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

-- entry point  
parse_rib( arg[1],fnclosure());
