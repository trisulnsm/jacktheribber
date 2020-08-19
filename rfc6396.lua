-- Implements RFC6396 , subset TABLEDUMP_V2 for BGP RIB Dumps 
-- using the fantastic bitmaul library 
local h=require 'handlers' 
local IP6=require'ip6'
local SWP=require'sweepbuf'

local H  =  {

	-- common header
	["mrt-common-header"] = function(payload)

		local sw=SWP.new(payload);

		return {
			timestamp = sw:next_u32(),
			type = sw:next_u16(),
			subtype = sw:next_u16(),
			length = sw:next_u32(),
		}

	end,

	-- TABLEDUMP_v2, PEER_INDEX 
	[13] = {
	
		[1] = function(payload)

			local sw=SWP.new(payload);

			local ret=  {
				collector_bgp_id = sw:next_ipv4(),
				view_name = sw:next_str_to_len(sw:next_u16()),
				peer_count = sw:next_u16(),
				peer_table = {},
			}
			for i=1,ret.peer_count do 
				local peer_entry = {
					peer_type = sw:next_bitfield_u8( {6,1,1}),
					peer_bgp_id = sw:next_ipv4(),
				}
				peer_entry.peer_ip =  peer_entry.peer_type[3]==0 and sw:next_ipv4() or  IP6.bin_to_ip6(sw:next_str_to_len(16))
				peer_entry.peer_as =  peer_entry.peer_type[2]==0 and sw:next_u16() or  sw:next_u32()
				table.insert(ret.peer_table, peer_entry)
			end
			return ret
		end,

		-- IPv4 UNICAST RIB ENTRY 
		[2] = function(payload, peer_filter_fn  )

			local sw=SWP.new(payload);

			local ret=  {
				sequence_no = sw:next_u32(),
				prefix = parse_prefix(sw),
				entry_count = sw:next_u16(),
				rib_table = {},
			}


			for i=1,ret.entry_count  do 

				local rib_entry  = {
					peer_index  = sw:next_u16(),
					originated_time   = sw:next_u32(),
					attributes = { } 
				}

				rib_entry.peer_ip = g_peer_index[ rib_entry.peer_index + 1 ]
				if not rib_entry.peer_ip  then 
					-- peer_index not found 
					sw:skip(sw:next_u16())
					goto nextrib
				end
				if not peer_filter_fn(rib_entry.peer_ip.peer_ip) then
					sw:skip(sw:next_u16())
					goto nextrib
				end 	

				-- path attributes
				flds = rib_entry.attributes 
				if sw:bytes_left() < 2 then return ret end 
				flds.path_attr_length   = sw:next_u16()
				flds.path_attr  = {}
				sw:push_fence(flds.path_attr_length)
				while sw:has_more() do 

				  local attr_flags = sw:next_bitfield_u8( {1,1,1,1,4} )
				  local attr_type = sw:next_u8()
				  local attr_len
				  if attr_flags[4]==1 then 
					attr_len = sw:next_u16() 
				  else
					attr_len = sw:next_u8() 
				  end 

				  local path_attr_fn  = BGP_Path_Attributes[attr_type]
				  if path_attr_fn then
				    local k,v  = path_attr_fn(sw,attr_len)
					flds.path_attr[k]=v
				  else
					flds.path_attr[attr_type]= attr_len
					sw:skip(attr_len) 
				  end

				end 

				table.insert(ret.rib_table, rib_entry )


				::nextrib::
			end
			return ret
		end,
	}

};

H[13][4]=H[13][2]

return H;
