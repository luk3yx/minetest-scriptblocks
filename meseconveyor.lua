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
