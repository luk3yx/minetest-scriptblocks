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



local digiconveyor_rules = {
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

local overlay_off = "^rmod_digiconveyor_overlay_off.png"
local overlay_on = "^rmod_digiconveyor_overlay_on.png"

local side_overlay_off = "^rmod_digiconveyor_side_overlay_off.png"
local side_overlay_on = "^rmod_digiconveyor_side_overlay_on.png"

local rmod_digiconveyor_top_off = "rmod_conveyor_top_off.png" .. overlay_off -- Un-animated version of the conveyor texture.
local rmod_digiconveyor_top_off_reversed = "rmod_conveyor_top_off_reversed.png" .. overlay_off -- I probably should just [rotate it.

local rmod_digiconveyor_top_animated_2 = rmod_conveyor_top_animated_2
rmod_digiconveyor_top_animated_2.name = rmod_conveyor_top_animated_2.name .. overlay_on

local rmod_digiconveyor_top_animated_2_reversed = rmod_conveyor_top_animated_2_reversed
rmod_digiconveyor_top_animated_2_reversed.name = rmod_conveyor_top_animated_2_reversed.name .. overlay_on



local function digiconveyor_off_digiline_receive (pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	local param2 = minetest.get_node(pos).param2
	if channel == setchan then
		if msg == "on" then
			minetest.swap_node(pos, {name = "rmod:digiconveyor_on", param2 = node.param2})
		elseif msg == "reverse" then
			minetest.swap_node(pos, {name = node.name, param2 = (node.param2 + 2) % 4})
		end
	end
end

local function digiconveyor_on_digiline_receive (pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	local param2 = minetest.get_node(pos).param2
	if channel == setchan then
		if msg == "off" then
			minetest.swap_node(pos, {name = "rmod:digiconveyor_off", param2 = node.param2})
		elseif msg == "reverse" then
			minetest.swap_node(pos, {name = node.name, param2 = (node.param2 + 2) % 4})
		end
	end
end

minetest.register_node("rmod:digiconveyor_off", {
	description = "Digiconveyor",
	tiles = {
		rmod_digiconveyor_top_off, rmod_digiconveyor_top_off,
		"rmod_conveyor_side.png" .. side_overlay_off, "rmod_conveyor_side.png" .. side_overlay_off,
		rmod_digiconveyor_top_off_reversed, rmod_digiconveyor_top_off
	},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	paramtype2 = "facedir",
	digiline = 
	{
		receptor = {},
		effector = {
			action = digiconveyor_off_digiline_receive
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;Channel;${channel}]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
})

minetest.register_node("rmod:digiconveyor_on", {
	description = "Active Digiconveyor (you hacker you!)",
	tiles = {
		rmod_digiconveyor_top_animated_2, rmod_digiconveyor_top_animated_2,
		"rmod_conveyor_side.png" .. side_overlay_on, "rmod_conveyor_side.png" .. side_overlay_on,
		rmod_digiconveyor_top_animated_2_reversed, rmod_digiconveyor_top_animated_2
	},
	groups = {oddly_breakable_by_hand = 1, conveyor = 1, not_in_creative_inventory = 1},
	drop = "rmod:digiconveyor_off",
	use_texture_alpha = true,
	paramtype2 = "facedir",
	digiline = 
	{
		receptor = {},
		effector = {
			action = digiconveyor_on_digiline_receive
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;Channel;${channel}]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.channel) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
})
