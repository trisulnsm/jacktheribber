--
-- PREFIX|PEER|ORIGIN|ASPATH
-- 
require 'jtribber'
local Tbl=require 'inspect'

-- usage test_file <filename> 
if #arg ~= 1 then 
  print("Usage : jtr_plain  <dumpfile>")
  return
end 


local fnclosure  = function()

	local k=0;
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

	end
end

parse_rib( arg[1],fnclosure());
