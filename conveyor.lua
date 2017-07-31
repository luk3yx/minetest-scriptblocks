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

local rmod_conveyor_top_animated_2_reversed = {
			name = "rmod_conveyor_top_animated_2.png", -- Higher resolution version with 4 frames as opposed to 2.
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1/8, -- it takes 1 second to move 16 pixels, thus 1/16 seconds to move one pixel. but this animation is two pixels per runthrough.
			},
		}

local rmod_conveyor_top_animated_2 = { -- Reversed animation for the Z+ face.
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

local getnode = function (pos)
	return minetest.get_node(pos)
end
local getname = function (pos)
	return getnode(pos).name
end
local getdef = function (pos)
	return minetest.registered_nodes[getname(pos)]
end
local round = function (n)
	return math.floor(n + 0.5)
end

local timer = 0

minetest.register_globalstep(function (dtime)
	timer = timer + dtime
	if timer > 1 then timer = 0 else return end  -- The code below should only execute once every second.
	for _,entity in pairs(minetest.object_refs) do  -- We cycle the entities because it then means we don't have to try to keep a queue of each entity.
		local isplayer = entity.get_player_name  -- We have is_player, but it doesn't seem to work too well atm.
		
		local position = entity:getpos()
			local roundedpos = {x=round(position.x), y=round(position.y), z=round(position.z)}
		
		local surface = vector.subtract(roundedpos, {x=0,y=1,z=0})
			local node = getnode(surface)
			local name = getname(surface)
			local def = getdef(surface)
		
		if name == "rmod:conveyor" then  -- I might replace this with a group, e.g. def.groups.conveyor, so you can set the speed.
			local facing = node.param2  -- Param2 is the facedir as defined above - conveyors face the opposite direction they move you.
				local direction = minetest.facedir_to_dir(facing)
				local movement = vector.multiply(direction, {x=1, y=1, z=1})  -- We reversed the facing system recently.
			
			local newpos = vector.add(position, movement)
				local newrpos = {x=round(newpos.x), y=round(newpos.y), z=round(newpos.z)}
				local newnode = getnode(newrpos)
				local newname = getname(newrpos)
				local newdef = getdef(newrpos)
			
			-- If we can move the player forward, we'll need to check here anyway.
			-- If we can move any entity forward and up, we'll need to check here.
			local upos = vector.add(newpos, {x=0, y=1, z=0})
				local roundedupos = {x=round(upos.x), y=round(upos.y), z=round(upos.z)}
				local unode = getnode(roundedupos)
				local uname = getname(roundedupos)
				local udef = getdef(roundedupos)
			
			if newdef.walkable then
				if newname == "rmod:conveyor" and newnode.param2 == facing then
					-- Okay, so the entity will be moving into a node.
					-- But it just so happens that this node is also a conveyor!
					-- Plus, it's moving in the same direction!
					-- Let's see if we can move the entity up and forward.
					
					-- We should also probably check for the node above it, if the entity is a player.
					-- We don't want their head in a node, after all.
					local uupos = vector.add(upos, {x=0, y=1, z=0})
						local roundeduupos = {x=round(uupos.x), y=round(uupos.y), z=round(uupos.z)}
						local uunode = getnode(roundeduupos)
						local uuname = getname(roundeduupos)
						local uudef = getdef(roundeduupos)
					
					if not udef.walkable and ((not isplayer) or (not uudef.walkable)) then  -- Ooh! We /can/ move the entity here!
						entity:setpos(upos)
					end
				end
			elseif (not is_player) or (not udef.walkable) then  -- When we move the entity, either the entity's not a player, or they have head room.
				entity:setpos(newpos)
			end
		end
	end
	--[[for pos,node in pairs(queue) do
		local facedir = minetest.facedir_to_dir(node.param2)
		for _,entity in pairs(minetest.get_objects_inside_radius(pos, 1)) do
			if entity and not entity_queue[entity] then
				local offset = vector.subtract(entity:getpos(), pos)
				local movementDir = vector.multiply(facedir, {x=1,y=1,z=1})
				if math.abs(offset.x) < 0.8 and math.abs(offset.z) < 0.8 and offset.y > 0 then
					local new_pos = vector.add(entity:getpos(), movementDir)
					local rounded_pos = {x=math.floor(new_pos.x+0.5),y=math.floor(new_pos.y+0.5),z=math.floor(new_pos.z+0.5)}
					
					if not getdef(rounded_pos).walkable then
						entity:setpos(new_pos)
						entity_queue[entity] = true
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
							entity_queue[entity] = true
							queue[pos] = nil
						end
					end
				end
			end
		end
	end]]
	--queue = {}
end)


