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
	if level < 8 then level = level * 2 else level = (level - 8) * 2 end
	if neigh_def.liquidtype == "source" then level = 16 end
	
	-- Check the opposing neighbor.
	local opposite = vector.subtract(pos, offset)
	local opposite_node = minetest.get_node(opposite)
	local opposite_name
	if opposite_node then opposite_name = opposite_node.name else return end
	local opposite_def = minetest.registered_nodes[opposite_name]
	if not opposite_def then return end
	
	if not opposite_def.floodable then 
		if not opposite_def.liquidtype then return end
		if opposite_def.walkable then return end
		
		local opposite_level = opposite_node.param2 % 16
		if opposite_level < 8 then opposite_level = opposite_level * 2 end
		if opposite_def.liquidtype == "source" then opposite_level = 16 end
		
		if opposite_level > level - 2 or opposite_def.liquidtype == "source" then return end
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
	if new_param2 < 1 then return end
	minetest.set_node(flow_to, {
		name = neigh_flowing,
		param1 = neigh_node.param1,
		param2 = new_param2
	})
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
