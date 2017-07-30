local rmod_conveyor_top_animated = {
			name = "rmod_conveyor_top_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1/8, -- it takes 1 second to move 16 pixels, thus 1/16 seconds to move one pixel. but this animation is two pixels per runthrough.
			},
		}

local rmod_conveyor_top_animated_2 = {
			name = "rmod_conveyor_top_animated_2.png", -- Higher resolution version with 4 frames as opposed to 2.
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1/8, -- it takes 1 second to move 16 pixels, thus 1/16 seconds to move one pixel. but this animation is two pixels per runthrough.
			},
		}

local rmod_conveyor_top_animated_2_reversed = { -- Reversed animation for the Z+ face.
			name = "rmod_conveyor_top_animated_2_reversed.png", -- Higher resolution version with 4 frames as opposed to 2.
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1/8, -- it takes 1 second to move 16 pixels, thus 1/16 seconds to move one pixel. but this animation is two pixels per runthrough.
			},
		}

minetest.register_node("rmod:conveyor", {
	description = "Conveyor",
	--[[tiles = {"rmod_conveyor_top.png", "rmod_conveyor_top.png", "rmod_conveyor_side.png", "rmod_conveyor_side.png", "rmod_conveyor_top.png", "rmod_conveyor_top.png"},]]
	tiles = {
		rmod_conveyor_top_animated_2, rmod_conveyor_top_animated_2,
		"rmod_conveyor_side.png", "rmod_conveyor_side.png",
		rmod_conveyor_top_animated_2_reversed, rmod_conveyor_top_animated_2 -- You have to reverse one of the faces to go UP, not DOWN.
	},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	paramtype2 = "facedir",
})

local queue = {}
local entity_queue = {}

minetest.register_abm({
	label = "Conveyor Step",
	nodenames = {"rmod:conveyor"},
	neighbors = {},
	interval = 1,
	chance = 1,
	action = function (pos, node)
		entity_queue = {}
		queue[pos] = node
	end,
})

	local getdef = function (pos)
		return minetest.registered_nodes[minetest.get_node(pos).name]
	end
	

minetest.register_globalstep(function (dtime)
	for pos,node in pairs(queue) do
		local facedir = minetest.facedir_to_dir(node.param2)
		for _,entity in pairs(minetest.get_objects_inside_radius(pos, 1)) do
			if entity and not entity_queue[entity:get_player_name()] then
				local offset = vector.subtract(entity:getpos(), pos)
				local movementDir = vector.multiply(facedir, {x=-1,y=-1,z=-1})
				if math.abs(offset.x) < 0.8 and math.abs(offset.z) < 0.8 and offset.y > 0 then
					local new_pos = vector.add(entity:getpos(), movementDir)
					local rounded_pos = {x=math.floor(new_pos.x+0.5),y=math.floor(new_pos.y+0.5),z=math.floor(new_pos.z+0.5)}
					
					if not getdef(rounded_pos).walkable then
						entity:setpos(new_pos)
						entity_queue[entity:get_player_name()] = true
						queue[pos] = nil
					end
				elseif math.abs(offset.x) < 2 and math.abs(offset.z) < 2 and offset.y < 0 then
					-- Take the movementDir, and subtract it from my position. Then subtract y=0.5. Players here should move UP.
					local moveUpPos = vector.subtract(vector.subtract(pos, movementDir), {x=0,y=0.5,z=0})
					local offset = vector.subtract(entity:getpos(), moveUpPos)
					local new_pos = vector.add(vector.add(entity:getpos(), {x=0,y=1,z=0}), movementDir)
					local obpos = vector.add(pos, {x=0,y=1,z=0}) -- check the node 1 above of us.
					local obpos2 = vector.add(pos, {x=0,y=2,z=0}) -- 2 above.
					if not (getdef(obpos).walkable or getdef(obpos2).walkable) then
						if math.abs(offset.x) < 0.5 and math.abs(offset.z) < 0.5 and math.abs(offset.y) < 0.5 then
							entity:setpos(new_pos)
							entity_queue[entity:get_player_name()] = true
							queue[pos] = nil
						end
					end
				end
			end
		end
	end
	queue = {}
end)
