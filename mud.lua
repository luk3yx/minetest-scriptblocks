minetest.register_node("rmod:mud", {
	drawtype = "flowingliquid",
	tiles = {"rmod_mud.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	
	walkable = false,
	
	after_place_node = function (pos)
		local node = minetest.get_node(pos)
		node.param2 = 0
		minetest.set_node(pos, node)
	end
})
