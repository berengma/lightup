-- There shall be light !
--
-- WTFPL by Gundul


local timer = 0				-- do not touch
local check = 0.5				-- intervall in which is checked for light, the smaller the more realistic but the harder for cpu
local turnoff = 1				-- after how many seconds the light is turned off again
local distance = 20				-- max distance of the torchlight
local brightness = 14			-- max brightness


minetest.register_privilege("lightup", {description ="automatic light in air and water"})




minetest.register_node("lightup:brightwater", {
	description = ("Water Source"),
	drawtype = "liquid",
	waving = 3,
	tiles = {
		{
			name = "default_water_source_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
		{
			name = "default_water_source_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	alpha = 191,
	light_source = brightness,
	paramtype = "light",   -- this is important !! do not use "light"
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	sounds = default.node_sound_water_defaults(),
})



minetest.register_lbm({                            -- this is to remove old bright water nodes after server crash etc
	name = "lightup:delete_lights",
	run_at_every_load = true,
		nodenames = {"lightup:brightwater"},
		action = function(pos, node)
				minetest.set_node(pos, {name = "default:water_source"})
		end,
	})

minetest.register_lbm({                            -- this is to remove old bright water nodes after server crash etc
	name = "lightup:delete_airlights",
	run_at_every_load = true,
		nodenames = {"lightup:brightair"},
		action = function(pos, node)
				minetest.set_node(pos, {name = "air"})
		end,
	})


local function clone_node(node_name)
	if not (node_name and type(node_name) == 'string') then
		return
	end

	local node = minetest.registered_nodes[node_name]
	return table.copy(node)
end


local function find_collision(pos1,dir)
	
	pos1 = mobkit.pos_shift(pos1,vector.multiply(dir,1))
	local pos2 = mobkit.pos_shift(pos1,vector.multiply(dir,distance))
	local ray = minetest.raycast(pos1, pos2, true, false)
			for pointed_thing in ray do
				if pointed_thing.type == "node" then
					local dist = math.floor(vector.distance(pos1,pointed_thing.under))
					pos2 = mobkit.pos_shift(pos1,vector.multiply(dir,dist-1))
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



local air = clone_node("air")
air.light_source = brightness
minetest.register_node('lightup:brightair', air)



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
						if node and node.name == "default:water_source" then
							minetest.swap_node(target, {name="lightup:brightwater"})
							minetest.after(turnoff,function(target)
										minetest.swap_node(target, {name="default:water_source"})
										end, target)
						end
                            
						if node and node.name == "default:water_flowing" then
							minetest.swap_node(target, {name="lightup:brightwater"})
							minetest.after(turnoff,function(target)
										minetest.swap_node(target, {name="default:water_flowing"})
										end, target)
						end
						
						if node and node.name == "air" then
							minetest.swap_node(target, {name="lightup:brightair"})
							minetest.after(turnoff,function(target)
										minetest.swap_node(target, {name="air"})
										end, target)
						end
				end
			end
		end
		
	timer = 0
	end
end)

