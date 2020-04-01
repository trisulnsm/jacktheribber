-- jacktheribber.lua
-- 
-- BGP MRT format TABLE_DUMP_v2 RIB dumper/utility 
--

local Rfc6396=require'rfc6396'
local Tbl=require'inspect'


-- callback_fn = function( fields_table ) 
--
function parse_rib( rib_file, callback_fn) 

	g_peer_index  = {} 
	local f,_err = io.open(rib_file)
	if not f then
		print("Unable to open "..rib_file.." : ".._err)
		return
	end 


	-- loop and yield 
	while true do

		-- the MRT header 
		local hpayload = f:read( 12)
		if hpayload == nil then break end
		local handler = Rfc6396['mrt-common-header']
		local header_fields = handler(hpayload)

		-- the MRT record 
		hpayload = f:read( header_fields.length)
		handler = Rfc6396[header_fields.type][header_fields.subtype]
		local mrt_fields = handler(hpayload)

		-- the peer index 
		if header_fields.type == 13 and header_fields.subtype == 1 then
			g_peer_index=mrt_fields.peer_table 
		end 	

		callback_fn(mrt_fields)
	end 

	f:close()
end 

