minetest.register_node("rmod:grate", {
	description = "Grate",
	tiles = {"rmod_grate.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	drawtype = "allfaces", --"glasslike",
	paramtype = "light",
})

local function get_level(node, def)
	local level = node.param2 % 16
	if level > 8 then level = level - 8 end
	if def and def.liquidtype == "source" then level = 8 end  -- Ooh, this node is a SOURCE! MAX LEVEL!
	if def and def.liquidtype ~= "flowing" and def.liquidtype ~= "source" then
		level = def.floodable and 0 or 8  -- Okay, the node isn't liquid. But we can still determine whether it contains undisplaceable matter.
	end
	if not def then level = 8 end
	
	return level
end

local function get_variables(pos)
	local node = minetest.get_node(pos)
	local name
	if node then name = node.name else return end
	local def = minetest.registered_nodes[name]
	local level = get_level(node, def)
	
	return node, name, def, level
end

local function calculate_level(pos)
	return ({get_variables(pos)})[4]
end

local function attempt_flow_to(pos1, pos2, dec)
	-- Try flowing from pos1 to pos2.
	local node1, name1, def1, level1 = get_variables(pos1)
	-- Flowing1 is the node we may or may not eventually place.
	local flowing1 = def1.liquid_alternative_flowing
	
	local node2, name2, def2, level2 = get_variables(pos2)
	
	if def1.liquidtype ~= "source" and def1.liquidtype ~= "flowing" then return end
	if not flowing1 then return end  -- node might not be a liquid.
	
	-- If we're flowing down, gravity is most likely going to aid.
	-- Therefore, we should set the values accordingly.
	if pos2.y < pos1.y then
		level1 = 8 + dec
		if def2.liquidtype == "flowing" then
			level2 = 0
			dec = 0
		end
	-- Opposite reasoning of above.
	elseif pos2.y > pos1.y then return end
	
	-- When water flows normally, it slowly decreases as it spreads outwards.
	-- Dec is the variable applied to the originating liquid's level, which
	-- the resulting output flow is decreased by.
	-- Usually this value is 2, but I'm allowing for customization.
	if level1 - dec <= level2 then return end
	
	if level1 - dec < 0 then return end
	minetest.set_node(pos2, {
		name = flowing1,
		param1 = pos1.param1,
		param2 = level1 - dec
	})
	
	return true
end

local function grate_step(pos, offset)
	local pos1 = vector.add(pos, offset)
	
	if not attempt_flow_to(pos1, vector.subtract(pos, {x=0,y=1,z=0}), 2) then  -- If we can't flow below...
		local left_offset = {x = offset.z, y = 0, z = -offset.x}
		local right_offset = {x = -offset.z, y = 0, z = offset.x}
		
		attempt_flow_to(pos1, vector.subtract(pos, offset), 2)  -- Try flowing forward.
		attempt_flow_to(pos1, vector.add(pos, left_offset), 2)  -- Try flowing left.
		attempt_flow_to(pos1, vector.add(pos, right_offset), 2)  -- And try flowing right.
	end
	--[[local neigh = vector.add(pos, offset)
	local neigh_node, neigh_name, neigh_def, level = get_variables(neigh)
	if not neigh_def then return end -- Unknown nodes can't flow.
	if neigh_def.liquidtype ~= "source" and neigh_def.liquidtype ~= "flowing" then return end -- Non-liquids can't flow at all.

	local neigh_flowing = neigh_def.liquid_alternative_flowing
	if not neigh_flowing then return end -- Improperly configured liquids can't flow.
	
	-- Check the opposing neighbor.
	local opposite = vector.subtract(pos, offset)
	
	local flowto_opposite = true
		
	local opposite_level = calculate_level(opposite)
	if opposite_level > level - 2 then flowto_opposite = false end
	
	local flow_to = opposite
	local gravity_affected = false
	
	if vector.equals(offset, {x=0, y=-1, z=0}) then
		-- Silly code, water can't flow UP!
		return
	elseif vector.equals(offset, {x=0, y=1, z=0}) then
		-- Water is very good at flowing down. Set to a high value.
		minetest.set_node(flow_to, {
			name = neigh_flowing,
			param1 = neigh_node.param1,
			param2 = 6
		})
		return
	else
		-- Great, water is flowing from the side, but what if the grate is above air?
		-- We should check if the water can flow down, first.
		local grav = vector.subtract(pos, {x=0, y=1, z=0})
		
		-- Meet the grav_node - the node that's below the grate.
		-- If liquids can flow into this node, we can forget about the opposite_node.
		
		local grav_level = calculate_level(grav)
		
		if grav_level < level - 2 then
			-- OOP! Sudden course change!
			flow_to = grav
			gravity_affected = true
		end
	end
	
	local new_param2 = neigh_def.liquidtype == "source" and 6 or neigh_node.param2 - 2
	if new_param2 < 0 then return end
	if flowto_opposite then
		minetest.set_node(flow_to, {
			name = neigh_flowing,
			param1 = neigh_node.param1,
			param2 = new_param2
		})
	end
	-- And we're done.
	
	
	
	-- WAIT! We're not done.
	if offset.y == 0 and not gravity_affected then
		local left_flow = {x = offset.z, y = 0, z = -offset.x}
			local left_pos = vector.add(pos, left_flow)
		local right_flow = {x = -offset.z, y = 0, z = offset.x}
			local right_pos = vector.add(pos, right_flow)
		
		local left_level = calculate_level(left_pos)
		
		local right_level = calculate_level(right_pos)
		
		if left_level < level - 2 then
			-- May as well spread here, too.
			minetest.set_node(left_pos, {
				name = neigh_flowing,
				param1 = neigh_node.param1,
				param2 = new_param2
			})
		end
		if right_level < level - 2 then
			-- May as well spread here, too.
			minetest.set_node(right_pos, {
				name = neigh_flowing,
				param1 = neigh_node.param1,
				param2 = new_param2
			})
		end
	end]]
end

minetest.register_abm({
	label = "Grate Step",
	nodenames = {"rmod:grate"},
	neighbors = {},
	interval = 1,
	chance = 1,
	action = function (pos, node)
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
			grate_step(pos, offset)
		end
	end,
})
