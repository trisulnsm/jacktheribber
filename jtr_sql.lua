-- jtr_sql
-- 
-- Stores routes from a specific V4 or v6 BGP peer 
-- into a SQLITE3 database 
-- 
-- sample command line 
-- luajit jtr_simple.lua  ribdump.000  238.1.23.22 17287  routes.sqdb 
-- 
require 'jtribber'
local lsqlite3 = require 'lsqlite3'

function create_schema(db)

	local create_stmt = [[CREATE TABLE IF NOT EXISTS PREFIX_PATHS_V4 ( PREFIX VARCHAR PRIMARY KEY, ASPATH VARCHAR, COMMUNITYPATH VARCHAR, NEXTHOP VARCHAR, TIMESTAMP INTEGER );
	CREATE TABLE IF NOT EXISTS PREFIX_PATHS_V6 ( PREFIX VARCHAR PRIMARY KEY, ASPATH VARCHAR, COMMUNITYPATH VARCHAR, NEXTHOP VARCHAR, TIMESTAMP INTEGER );
	CREATE TABLE IF NOT EXISTS LAST_KEEPALIVE ( TIMESTAMP INTEGER );
	CREATE TABLE IF NOT EXISTS EVENTS ( TIMESTAMP INTEGER, DESCRIPTIONVARCHAR );
	CREATE TABLE IF NOT EXISTS PEER_INFO ( ADDRESS VARCHAR PRIMARY KEY, DESCRIPTION VARCHAR );]]

	for m in create_stmt:gmatch("(.-;)") do
		db:exec(m)
	end

end


--------------------
-- usage test_file <filename> <peer_ip> 
if #arg ~= 4 then 
 print("Usage : jtr_sql <dumpfile> <only-this-peer-ip> <only-this-as> <sqldb> ")
 return
end 


local dbfile = arg[4]

local db,status=lsqlite3.open(dbfile);
if not db then
 print("Error open lsqlite3 err="..status)
 return nil
end 

create_schema(db)

local insert_4=db:prepare("INSERT OR REPLACE INTO PREFIX_PATHS_V4 VALUES(?,?,?,?,?);")
local insert_6=db:prepare("INSERT OR REPLACE INTO PREFIX_PATHS_V6 VALUES(?,?,?,?,?);")

-- 
-- Print each RIB Entry , Pipe Separated
-- 
local fnclosure  = function()
	local target_as = tonumber(arg[3])
	local insert_4=insert_4
	local insert_6=insert_6
	return function(mrt_record)
		if mrt_record.prefix then 
			local prefix=mrt_record.prefix
			local use_insert = prefix:find(':',1,true) and insert_6 or insert_4

			for idx,entry in ipairs(mrt_record.rib_table) do 
				local tbl={}

				local aspath_arr = entry.attributes.path_attr["AS_PATH"].aslist
				local found_pos=0
				for i,v in ipairs(aspath_arr) do
					if v==target_as then
						found_pos=i
						break
					end
				end 
				
				if found_pos > 0  then 

					local clip_aspath={}
					for i = found_pos+1, #aspath_arr do 
						table.insert(clip_aspath,aspath_arr[i])
					end
					use_insert:bind(1,prefix)
					use_insert:bind(2,table.concat(clip_aspath,' '))
					use_insert:bind(3,entry.attributes.path_attr["COMMUNITIES"])
					use_insert:bind(4,entry.attributes.path_attr["NEXTHOP"])
					use_insert:bind(5,entry.originated_time)

					use_insert:step()
					use_insert:clear_bindings()
					use_insert:reset()
				end 
				
			end 
		end
		return true
	end
end

-- filter only the peer_ip 
-- this dramatically speeds up 
local peer_filter_closure=function()
	local allow_this_ip = arg[2]
	return function(peer_ip)
		return peer_ip == allow_this_ip
	end
end 

-- entry point  
db:exec("BEGIN TRANSACTION")
parse_rib( arg[1],fnclosure(),peer_filter_closure());
db:exec("END TRANSACTION")
insert_4:finalize()
insert_6:finalize()
db:close()
