minetest.register_node("rmod:grate", {
	description = "Grate",
	tiles = {"rmod_grate.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	drawtype = "glasslike",
	paramtype = "light",
})

local function grate_step(pos, offset)
	local neigh = vector.add(pos, offset)
	local neigh_node = minetest.get_node(neigh)
	local neigh_name
	if neigh_node then neigh_name = neigh_node.name else return end
	local neigh_def = minetest.registered_nodes[neigh_name]
	if not neigh_def then return end -- Unknown nodes can't flow.
	if neigh_def.liquidtype ~= "source" and neigh_def.liquidtype ~= "flowing" then return end -- Non-liquids can't flow at all.
	
	-- Check its level.
	local level = neigh_node.param2 % 16
	if level > 8 then level = level - 8 end
	if neigh_def.liquidtype == "source" then level = 8 end
	
	-- Check the opposing neighbor.
	local opposite = vector.subtract(pos, offset)
	local opposite_node = minetest.get_node(opposite)
	local opposite_name
	if opposite_node then opposite_name = opposite_node.name else return end
	local opposite_def = minetest.registered_nodes[opposite_name]
	if not opposite_def then return end
	
	local flowto_opposite = true
	
	if not opposite_def.floodable then 
		if not opposite_def.liquidtype then flowto_opposite = false end
		if opposite_def.walkable then flowto_opposite = false end
		
		local opposite_level = opposite_node.param2 % 16
		if opposite_level > 8 then opposite_level = opposite_level - 8 end
		if opposite_def.liquidtype == "source" then opposite_level = 8 end
		
		if opposite_level > level - 2 or opposite_def.liquidtype == "source" then flowto_opposite = false end
	end -- Liquids can't flow into higher level liquids.
	local neigh_flowing = neigh_def.liquid_alternative_flowing
	if not neigh_flowing then return end -- Improperly configured liquids can't flow.
	
	local flow_to = opposite
	
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
		local grav_node = minetest.get_node(grav)
		local grav_name
		if grav_node then grav_name = grav_node.name end
		
		-- Meet the grav_node - the node that's below the grate.
		-- If liquids can flow into this node, we can forget about the opposite_node.
		
		if grav_node and grav_name == "air" then
			-- OOP! Sudden course change!
			flow_to = grav
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
	if offset.y == 0 then
		local left_flow = {x = offset.z, y = 0, z = -offset.x}
			local left_pos = vector.add(pos, left_flow)
			local left_node = minetest.get_node(left_pos)
			local left_name
			if left_node then left_name = left_node.name end
			local left_def = left_name and minetest.registered_nodes[left_name]
		local right_flow = {x = -offset.z, y = 0, z = offset.x}
			local right_pos = vector.add(pos, right_flow)
			local right_node = minetest.get_node(right_pos)
			local right_name
			if right_node then right_name = right_node.name end
			local right_def = right_name and minetest.registered_nodes[right_name]
		
		local left_level = left_node.param2 % 16
		if left_level > 8 then left_level = left_level - 8 end
		if left_def.liquidtype == "source" then left_level = 8 end
		
		local right_level = right_node.param2 % 16
		if right_level > 8 then right_level = right_level - 8 end
		if right_def.liquidtype == "source" then right_level = 8 end
		
		if left_node and (left_name == "air" or (left_def.liquidtype == "flowing" and left_level < level - 2)) then
			-- May as well spread here, too.
			minetest.set_node(left_pos, {
				name = neigh_flowing,
				param1 = neigh_node.param1,
				param2 = new_param2
			})
		end
		if right_node and (right_name == "air" or (right_def.liquidtype == "flowing" and right_level < level - 2)) then
			-- May as well spread here, too.
			minetest.set_node(right_pos, {
				name = neigh_flowing,
				param1 = neigh_node.param1,
				param2 = new_param2
			})
		end
	end
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
