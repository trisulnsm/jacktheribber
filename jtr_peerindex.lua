-- jtr_peerindex 
-- Print the BGP Peer Index only and exit 

require 'jtribber'
local Tbl=require 'inspect'

-- usage test_file <filename> 
if #arg ~= 1 then 
  print("Usage : jtr_peerindex  <dumpfile>")
  return
end 


local fnclosure  = function()

	local k=0;
	return function(mrt_record)
		print(Tbl.inspect(mrt_record))
		return false
	end
end

parse_rib( arg[1],fnclosure());
