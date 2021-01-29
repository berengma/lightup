-- There shall be light !
--
-- WTFPL by Gundul

lightup = {}
lightup.switch = {}

local timer = 0				-- do not touch
local check = 0.1				-- intervall in which is checked for light, the smaller the more realistic but the harder for cpu
local turnoff = 0.2				-- after how many seconds the light is turned off again
local distance = 20				-- max distance of the torchlight
local brightness = 14			-- max brightness


minetest.register_privilege("lightup", {description ="automatic light in air and water"})


-- register water and airnodes, together with their new brothers. 
lightup.switch[1] = {name="default:water_source", change="lightup:brightwater"}
lightup.switch[2] = {name="default:water_flowing", change="lightup:brightwater_flowing"}
lightup.switch[3] = {name="default:river_water_source", change="lightup:brightriverwater"}
lightup.switch[4] = {name="default:river_water_flowing", change="lightup:brightriverwater_flowing"}
lightup.switch[5] = {name="water_life:muddy_river_water_source", change="lightup:brightmuddywater"}
lightup.switch[6] = {name="water_life:muddy_river_water_flowing", change="lightup:brightmuddywater_flowing"}
lightup.switch[7] = {name="air", change="lightup:brightair"}


-- this function is taken from Termos' mobkit api.
local function pos_shift(pos,vec) -- vec components can be omitted e.g. vec={y=1}
	vec.x=vec.x or 0
	vec.y=vec.y or 0
	vec.z=vec.z or 0
	return {x=pos.x+vec.x,
			y=pos.y+vec.y,
			z=pos.z+vec.z}
end

-- the name says it all
local function clone_node(node_name)
	if not (node_name and type(node_name) == 'string') then
		return
	end

	local node = minetest.registered_nodes[node_name]
	return table.copy(node)
end


-- throwing a raycast
local function find_collision(pos1,dir)
	
	pos1 = pos_shift(pos1,vector.multiply(dir,1))
	local pos2 = pos_shift(pos1,vector.multiply(dir,distance))
	local ray = minetest.raycast(pos1, pos2, true, false)
			for pointed_thing in ray do
				if pointed_thing.type == "node" then
					local dist = math.floor(vector.distance(pos1,pointed_thing.under))
					pos2 = pos_shift(pos1,vector.multiply(dir,dist-1))
					return pos2
				end
				if pointed_thing.type == "object" then
					local obj = pointed_thing.ref
					local objpos = obj:get_pos()
					return objpos
				end
			end
	return nil
end


--register all that new bright nodes
for i = 1,#lightup.switch,1 do

	if minetest.registered_nodes[lightup.switch[i].name] and not minetest.registered_nodes[lightup.switch[i].change] then
		local water = clone_node(lightup.switch[i].name)
		water.liquid_alternative_flowing = lightup.switch[i].change
		water.liquid_alternative_source = lightup.switch[i].change
		water.groups.not_in_creative_inventory = 1
		water.light_source = brightness
		water.liquid_renewable = false
		water.on_timer = function(pos, elapsed)
						minetest.set_node(pos,{name=lightup.switch[i].name})				-- when node timer is elapsed turn back into src
					end
		minetest.register_node(lightup.switch[i].change, water)
	end
end



-- globalstep to check for people with lightup priv
-- change that check for a certain item in player inventory
-- or whatever you want and need

minetest.register_globalstep(function(dtime)

	timer = timer + dtime
	if timer > check then
        
		for _,plyr in ipairs(minetest.get_connected_players()) do
                            
			local name = plyr:get_player_name()
			local privs = minetest.get_player_privs(name)
			if privs.lightup or privs.server then
				local yaw = plyr:get_look_horizontal()
				local pos = plyr:get_pos()
				local dir = plyr:get_look_dir()
				pos.y = pos.y + 1.4
				local target = find_collision(pos,dir)
                    
				if target then		
						local node = minetest.get_node_or_nil(target)
						--minetest.chat_send_all(dump(node.name))
                            
						for i = 1,#lightup.switch,1 do
                            
							-- found a node ? change it into a bright brother
							if node and node.name == lightup.switch[i].name then
								minetest.swap_node(target, {name=lightup.switch[i].change})
								minetest.after(1,function(target)
											local timer = minetest.get_node_timer(target)
											timer:start(turnoff)
								end, target)
							end
							
							-- still pointing to a bright node ? set nodetimer to max again.
							if node and node.name == lightup.switch[i].change then
								local timer = minetest.get_node_timer(target)
								if timer:is_started() then
									timer:set(turnoff,0)
								end
							end
						end
                            
				end
			end
		end
		
	timer = 0
	end
end)

