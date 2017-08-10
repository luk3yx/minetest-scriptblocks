minetest.register_node("rmod:grate", {
	description = "Grate",
	tiles = {"rmod_grate.png"},
	groups = {oddly_breakable_by_hand = 1, grate = 2},
	use_texture_alpha = true,
	drawtype = "glasslike",
	paramtype = "light",
})

local function get_level(node, def)
	local level = node.param2 % 16
	local falling = false
	
	if level > 8 then level = level - 8; falling = true end
	if def and def.liquidtype == "source" then level = 8 end  -- Ooh, this node is a SOURCE! MAX LEVEL!
	if def and def.liquidtype ~= "flowing" and def.liquidtype ~= "source" then
		level = def.floodable and -1 or math.huge  -- Okay, the node isn't liquid. But we can still determine whether it contains undisplaceable matter.
	end
	if not def then level = 8 end
	
	return level, falling
end

local function get_variables(pos)
	local node = minetest.get_node(pos)
	local name
	if node then name = node.name else return end
	local def = minetest.registered_nodes[name]
	local level, falling = get_level(node, def)
	
	return node, name, def, level, falling
end

local function calculate_level(pos)
	return ({get_variables(pos)})[4], ({get_variables(pos)})[5]
end

local function attempt_flow_to(pos1, pos2, dec)
	-- Try flowing from pos1 to pos2.
	local node1, name1, def1, level1, falling1 = get_variables(pos1)
	-- Flowing1 is the node we may or may not eventually place.
	local flowing1 = def1.liquid_alternative_flowing
	
	-- Non-liquids can't flow, derrr.
	if def1.liquidtype ~= "source" and def1.liquidtype ~= "flowing" then return end
	if not flowing1 then return end
	
	-- If this water is falling, it's not about to spread out just because a grate's nearby.	
	if falling1 then return end
	
	local node2, name2, def2, level2, falling2 = get_variables(pos2)
	
	-- If we're flowing down, gravity is most likely going to aid.
	-- Therefore, we should set the values accordingly.
	local gravity = false
	if pos2.y < pos1.y then
		gravity = true
	-- Opposite reasoning of above.
	elseif pos2.y > pos1.y then return end
	
	local new_level = level1 - dec
	if gravity then new_level = 15 end
	
	-- When water flows normally, it slowly decreases as it spreads outwards.
	-- Dec is the variable applied to the originating liquid's level, which
	-- the resulting output flow is decreased by.
	-- Usually this value is 2, but I'm allowing for customization.
	if new_level <= level2 then return end
	
	-- Well, duh! Water can't have a negative level!
	if new_level < 0 then return end
	minetest.set_node(pos2, {
		name = flowing1,
		param1 = pos1.param1,
		param2 = new_level
	})
	
	return true
end

local function grate_step(pos, offset, grate)
	local pos1 = vector.add(pos, offset)
	
	if not attempt_flow_to(pos1, vector.subtract(pos, {x=0,y=1,z=0}), grate) then  -- If we can't flow below...
		local left_offset = {x = offset.z, y = 0, z = -offset.x}
		local right_offset = {x = -offset.z, y = 0, z = offset.x}
		
		attempt_flow_to(pos1, vector.subtract(pos, offset), grate)  -- Try flowing forward.
		attempt_flow_to(pos1, vector.add(pos, left_offset), grate)  -- Try flowing left.
		attempt_flow_to(pos1, vector.add(pos, right_offset), grate)  -- And try flowing right.
	end
end

rmod.grate = {}
rmod.grate.flow = function (pos, node, dec)
	for i=1,5 do -- For each of our 5 neighbors, (excluding the node from below, of course)
		-- Calculate where our neighbor is
		local offset = {x=0,y=0,z=0}
		if i == 1 then offset.y = 1 end
		--if i == 2 then offset.y = -1 end
		if i == 2 then offset.x = 1 end
		if i == 3 then offset.x = -1 end
		if i == 4 then offset.z = 1 end
		if i == 5 then offset.z = -1 end
		-- Then run the checking code
		grate_step(pos, offset, dec)
	end
end

minetest.register_abm({
	label = "Grate Step",
	nodenames = {"group:grate"},
	neighbors = {},
	interval = 1,
	chance = 1,
	action = function (pos, node) rmod.grate.flow(pos, node, 2) end
})
