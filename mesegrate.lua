minetest.register_node("rmod:mesegrate_off", {
	description = "Mesegrate",
	tiles = {"rmod_grate.png^rmod_mesegrate_overlay_off.png"},
	groups = {oddly_breakable_by_hand = 1, mesecon = 2},
	use_texture_alpha = true,
	--drawtype = "glasslike",
	paramtype = "light",
	mesecons = {
		conductor = {
			-- rules = rules,
			state = mesecon.state.off,
			onstate = "rmod:mesegrate_on"
		},		
		effector = {
			action_on = function (pos, node)
				minetest.swap_node(pos, {name = "rmod:mesegrate_on", param2 = node.param2})
			end,
		}
	}
})

minetest.register_node("rmod:mesegrate_on", {
	description = "Active Mesegrate (you hacker you!)",
	tiles = {"rmod_grate.png^rmod_mesegrate_overlay_on.png"},
	groups = {oddly_breakable_by_hand = 1, grate = 2, mesecon = 2, not_in_creative_inventory = 1},
	use_texture_alpha = true,
	drawtype = "glasslike",
	paramtype = "light",
	mesecons = {
		conductor = {
			-- rules = rules,
			state = mesecon.state.on,
			offstate = "rmod:mesegrate_off"
		},
		effector = {
			action_off = function (pos, node)
				minetest.swap_node(pos, {name = "rmod:mesegrate_off", param2 = node.param2})
			end,
		}
	},
	drop = "rmod:mesegrate_off"
})
