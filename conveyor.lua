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
	groups = {oddly_breakable_by_hand = 1, conveyor = 1},
	use_texture_alpha = true,
	paramtype2 = "facedir",
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
		local isplayer = entity:is_player()
		
		local position = entity:getpos()
			local roundedpos = {x=round(position.x), y=round(position.y), z=round(position.z)}
		
		local surface = vector.subtract(roundedpos, {x=0,y=1,z=0})
			local node = getnode(surface)
			local name = getname(surface)
			local def = getdef(surface)
		
		if def and def.groups.conveyor == 1 then  -- I might replace this with a group, e.g. def.groups.conveyor, so you can set the speed.
			local facing = node.param2  -- Param2 is the facedir as defined above - conveyors face the opposite direction they move you.
				local direction = minetest.facedir_to_dir(facing)
				local movement = vector.multiply(direction, {x=1, y=1, z=1})  -- We reversed the facing system recently.
			
			local newpos = vector.add(position, movement)
				local newrpos = {x=round(newpos.x), y=round(newpos.y), z=round(newpos.z)}
				local newnode = getnode(newrpos)
				local newname = getname(newrpos)
				local newdef = getdef(newrpos)
			
			-- If we can move any entity forward and up, we'll need to check here.
			-- If we can move the player forward, we'll need to check here anyway.
			local upos = vector.add(newpos, {x=0, y=1, z=0})
				local roundedupos = {x=round(upos.x), y=round(upos.y), z=round(upos.z)}
				local unode = getnode(roundedupos)
				local uname = getname(roundedupos)
				local udef = getdef(roundedupos)
			
			if newdef.walkable then
				if newdef.groups.conveyor == 1 and newnode.param2 == facing then
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
			elseif (not isplayer) or (not udef.walkable) then  -- When we move the entity, either the entity's not a player, or they have head room.
				entity:setpos(newpos)
			end
		end
	end
end)



if not minetest.get_modpath("mesecons") then return end -- There's no point of using meseconveyors when mesecons doesn't exist.

-- I present... Meseconveyors!

local meseconveyor_rules = {
	{x=0,  y=0,  z=-1},
	{x=1,  y=0,  z=0},
	{x=-1, y=0,  z=0},
	{x=0,  y=0,  z=1},
	{x=1,  y=1,  z=0},
	{x=1,  y=-1, z=0},
	{x=-1, y=1,  z=0},
	{x=-1, y=-1, z=0},
	{x=0,  y=1,  z=1},
	{x=0,  y=-1, z=1},
	{x=0,  y=1,  z=-1},
	{x=0,  y=-1, z=-1},
	{x=0,  y=-1, z=0},
}

local overlay_off = "^rmod_meseconveyor_overlay_off.png"
local overlay_on = "^rmod_meseconveyor_overlay_on.png"

local side_overlay_off = "^rmod_meseconveyor_side_overlay_off.png"
local side_overlay_on = "^rmod_meseconveyor_side_overlay_on.png"

local rmod_meseconveyor_top_off = "rmod_conveyor_top_off.png" .. overlay_off -- Un-animated version of the conveyor texture.
local rmod_meseconveyor_top_off_reversed = "rmod_conveyor_top_off_reversed.png" .. overlay_off -- I probably should just [rotate it.

local rmod_meseconveyor_top_animated_2 = rmod_conveyor_top_animated_2
rmod_meseconveyor_top_animated_2.name = rmod_conveyor_top_animated_2.name .. overlay_on

local rmod_meseconveyor_top_animated_2_reversed = rmod_conveyor_top_animated_2_reversed
rmod_meseconveyor_top_animated_2_reversed.name = rmod_conveyor_top_animated_2_reversed.name .. overlay_on

minetest.register_node("rmod:meseconveyor_off", {
	description = "Meseconveyor",
	tiles = {
		rmod_meseconveyor_top_off, rmod_meseconveyor_top_off,
		"rmod_conveyor_side.png" .. side_overlay_off, "rmod_conveyor_side.png" .. side_overlay_off,
		rmod_meseconveyor_top_off_reversed, rmod_meseconveyor_top_off
	},
	groups = {oddly_breakable_by_hand = 1, mesecon = 2},
	use_texture_alpha = true,
	paramtype2 = "facedir",
	mesecons = {effector = {
		rules = meseconveyor_rules,
		action_on = function (pos, node)
			minetest.swap_node(pos, {name = "rmod:meseconveyor_on", param2 = node.param2})
		end,
	}}
})

minetest.register_node("rmod:meseconveyor_on", {
	description = "Active Meseconveyor (you hacker you!)",
	tiles = {
		rmod_meseconveyor_top_animated_2, rmod_meseconveyor_top_animated_2,
		"rmod_conveyor_side.png" .. side_overlay_on, "rmod_conveyor_side.png" .. side_overlay_on,
		rmod_meseconveyor_top_animated_2_reversed, rmod_meseconveyor_top_animated_2
	},
	groups = {oddly_breakable_by_hand = 1, conveyor = 1, not_in_creative_inventory = 1, mesecon = 2},
	drop = "rmod:meseconveyor_off",
	use_texture_alpha = true,
	paramtype2 = "facedir",
	mesecons = {effector = {
		rules = meseconveyor_rules,
		action_off = function (pos, node)
			minetest.swap_node(pos, {name = "rmod:meseconveyor_off", param2 = node.param2})
		end,
	}}
})
