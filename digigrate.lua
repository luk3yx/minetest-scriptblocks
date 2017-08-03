local function calculate_dec (value)
	-- Our mission: convert a user-provided value (how open the grate should be),
	-- into a dec value (how much the water should decrease when it flows through a grate).
	-- 0 -> 8 = 2^3
	-- 50% -> 4 = 2^2
	-- 100% -> 2 = 2^1
	local max = 100 -- atm
	
	local dec = max - value  -- 0-50-100 -> 100-50-0
	dec = dec * 2 / max  -- 100-50-0 -> 2-1-0
	dec = dec + 1  -- 2-1-0 -> 3-2-1
	dec = 2^dec  -- 3-2-1 -> 8-4-2
	
	if dec > 8 then dec = 8 end
	if dec < 2 then dec = 2 end
	return math.floor(dec + 0.5)  -- We're storing the dec value as an int, simply because water cannot have a fractional level.
end

local function digigrate_off_digiline_receive (pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	local param2 = minetest.get_node(pos).param2
	if channel == setchan then
		if msg == "on" or msg == "toggle" then
			minetest.swap_node(pos, {name = "rmod:digigrate_on"})
		elseif type(msg) == "table" and msg.command == "set" and tonumber(msg.value) then
			minetest.get_meta(pos):set_int("dec", calculate_dec(tonumber(msg.value)))
		end
	end
end

local function digigrate_on_digiline_receive (pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	local param2 = minetest.get_node(pos).param2
	if channel == setchan then
		if msg == "off" or msg == "toggle" then
			minetest.swap_node(pos, {name = "rmod:digigrate_off"})
		elseif type(msg) == "table" and msg.command == "set" and tonumber(msg.value) then
			minetest.get_meta(pos):set_int("dec", calculate_dec(tonumber(msg.value)))
		end
	end
end


minetest.register_node("rmod:digigrate_off", {
	description = "Digigrate",
	tiles = {"rmod_grate.png^rmod_digigrate_overlay_off.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	--drawtype = "glasslike",
	paramtype = "light",
	digiline = 
	{
		receptor = {},
		effector = {
			action = digigrate_off_digiline_receive
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;Channel;${channel}]")
		meta:set_int("dec", 2)
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

minetest.register_node("rmod:digigrate_on", {
	description = "Active Digigrate (you hacker you!)",
	tiles = {"rmod_grate.png^rmod_digigrate_overlay_on.png"},
	groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
	use_texture_alpha = true,
	drawtype = "glasslike",
	paramtype = "light",
	digiline = {
		receptor = {},
		effector = {
			action = digigrate_on_digiline_receive
		},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[channel;Channel;${channel}]")
		meta:set_int("dec", 2)
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
	drop = "rmod:digigrate_off"
})

minetest.register_abm({
	label = "Digigrate Step",
	nodenames = {"rmod:digigrate_on"},
	neighbors = {},
	interval = 1,
	chance = 1,
	action = function (pos, node)
		local meta = minetest.get_meta(pos)
			local dec = meta:get_int("dec")
		rmod.grate.flow(pos, node, dec)
	end,
})
