--[[
	scriptblock = function (pos, node, sender, info, last, main_channel)
		-- "pos" and "node" are the position and the node information of the scriptblock being ran.
		-- "sender" would be the position of the node responsible for activating it.
		-- "info" is any information the previous node has sent to it.
		-- "last" is the information that "info" /was/ before it was last changed.
		-- "channel" is the channel in which variables are stored.
		blah blah blah
		return new_info, faces  -- Information to pass to the next node(s), and information on which adjacent spaces we should even try to signal to.
	end
]]

local program_channel = "Program channel"

local do_debug = false
local function debug(text)
	if do_debug then minetest.chat_send_all("[SB] " .. text) end
end

local storage = minetest.get_mod_storage()

-- Each section of the RMod gets its own storage, to prevent interference.
-- RMod sections can still affect other sections, though only when intended.
local function get_storage()
	return minetest.deserialize(storage:get_string("scriptblock")) or {}
end
local function set_storage(data)
	return storage:set_string("scriptblock", minetest.serialize(data))
end

-- To avoid lag and stack overflows, we add the data to a queue and then execute it with a globalstep.
local queue = {}

rmod.scriptblock = {}

rmod.scriptblock.run = function (pos, sender, info, last, channel)
	local local_queue = {}
	
	-- Get information about this script block we are told to execute.
	local node = minetest.get_node(pos)
		local name = node.name
			local def = minetest.registered_nodes[name]
	
	-- If the block is a script block...
	if def and def.scriptblock then
		local new_info, faces = def.scriptblock(pos, node, sender, info, last, channel)
		-- if new_info == rmod.scriptblock.stop_signal then return end  -- Looks like the block doesn't want to conduct.
		if not faces then
			faces = {true, true, true, true, true, true}
		end
		-- Check neighboring nodes; if they also have scriptblock and aren't the sender, execute them.
		for i=1,6 do
			if faces[i] then
				local dir = vector.new(0, 0, 0)
				    if i == 1 then dir.y = 1
				elseif i == 2 then dir.y = -1
				elseif i == 3 then dir.x = 1
				elseif i == 4 then dir.x = -1
				elseif i == 5 then dir.z = 1
				elseif i == 6 then dir.z = -1 end
			
				local new_pos = vector.add(pos, dir)
			
				-- This is required, otherwise you'd have an unintentional feedback loop.
				-- Feedback loops can still be created intentionally, though.
				if not vector.equals(new_pos, sender) then
					local new_node = minetest.get_node(new_pos)
						local new_name = new_node.name
							local new_def = minetest.registered_nodes[new_name]
			
					if new_def and new_def.scriptblock then
						table.insert(local_queue, {new_pos, pos, new_info, info == new_info and last or info, channel})
					end
				end
			end
		end
	end
	return local_queue
end
rmod.scriptblock.escape = function (text, info, last)
	if type(info) == "table" then info = minetest.serialize(info) or "" end
	if type(last) == "table" then last = minetest.serialize(last) or "" end
	return text and text:gsub("@info", info or ""):gsub("@last", last or "") or ""
end

local time = 0
minetest.register_globalstep(function (dtime)
	-- time = time + dtime
	-- if time > 0.05 then time = 0 else return end
	
	local new_queue = {}
	for i,data in pairs(queue) do
		local new_list = rmod.scriptblock.run(unpack(data))
		if new_list then
			for _,new_item in pairs(new_list) do
				table.insert(new_queue, new_item)
			end
		end
	end
	queue = new_queue
end)

minetest.register_node("rmod:scriptblock_set", {
	description = "Scriptblock: Set",
	tiles = {"rmod_scriptblock_set.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[channel;]] .. program_channel .. [[ (optional);${channel}]
field[varname;Varname;${varname}]
field[value;Value;${value}]
]])
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
		if (fields.varname) then
			minetest.get_meta(pos):set_string("varname", fields.varname)
		end
		if (fields.value) then
			minetest.get_meta(pos):set_string("value", fields.value)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local channel = rmod.scriptblock.escape(meta:get_string("channel"), info, last)
			local varname = rmod.scriptblock.escape(meta:get_string("varname"), info, last)
			local value = rmod.scriptblock.escape(meta:get_string("value"), info, last)
		
		local store = get_storage()
		
		if channel == "" or not channel then channel = main_channel end
		
		if not store[channel] then store[channel] = {} end
		store[channel][varname] = value

		set_storage(store)
		
		debug("SET " .. channel .. "." .. varname .. ": " .. value)
		
		return info
	end
})
minetest.register_node("rmod:scriptblock_get", {
	description = "Scriptblock: Get",
	tiles = {"rmod_scriptblock_get.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[channel;]] .. program_channel .. [[ (optional);${channel}]
field[varname;Varname;${varname}]
]])
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
		if (fields.varname) then
			minetest.get_meta(pos):set_string("varname", fields.varname)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local channel = rmod.scriptblock.escape(meta:get_string("channel"), info, last)
			local varname = rmod.scriptblock.escape(meta:get_string("varname"), info, last)
		
		local store = get_storage()
		
		if channel == "" or not channel then channel = main_channel end
		
		if not store[channel] then store[channel] = {} end
		
		debug("GET " .. channel .. "." .. varname .. ": " .. (store[channel][varname] or ""))
		
		return store[channel][varname] or ""
	end
})
minetest.register_node("rmod:scriptblock_mesecon", {
	description = "Scriptblock: Mesecon Detector",
	tiles = {"rmod_scriptblock_mesecon.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[channel;]] .. program_channel .. [[;${channel}]
]])
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
	scriptblock = function (pos, node, sender, info, last, main_channel)
		return info
	end,
	mesecons = {effector = {
		action_on = function (pos, node)
			local meta = minetest.get_meta(pos)
			local channel = meta:get_string("channel")
			
			debug("ACTIVATED")
			table.insert(queue, {pos, pos, "", "", channel or ""})
		end,
	}}
})
minetest.register_node("rmod:scriptblock_print", {
	description = "Scriptblock: Print",
	tiles = {"rmod_scriptblock_print.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[player;Player (optional);${player}]
field[message;Message;${message}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.player) then
			minetest.get_meta(pos):set_string("player", fields.player)
		end
		if (fields.message) then
			minetest.get_meta(pos):set_string("message", fields.message)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local plr = rmod.scriptblock.escape(meta:get_string("player"), info, last)
			local msg = rmod.scriptblock.escape(meta:get_string("message"), info, last)
		
		if plr == "" then
			minetest.chat_send_all("Scriptblock -> all: " .. msg)
		else
			minetest.chat_send_player(plr, "Scriptblock -> you: " .. msg)
		end
		
		return info
	end
})
minetest.register_node("rmod:scriptblock_if", {
	description = "Scriptblock: If Equals",
	tiles = {"rmod_scriptblock_if_top.png", "rmod_scriptblock_if_bottom.png",
		"rmod_scriptblock_if_right.png", "rmod_scriptblock_if_left.png",
		"rmod_scriptblock_if_truth.png", "rmod_scriptblock_if_falsth.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	paramtype2 = "facedir",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[a;A;${a}]
field[b;B;${b}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.a) then
			minetest.get_meta(pos):set_string("a", fields.a)
		end
		if (fields.b) then
			minetest.get_meta(pos):set_string("b", fields.b)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local a = rmod.scriptblock.escape(meta:get_string("a"), info, last)
			local b = rmod.scriptblock.escape(meta:get_string("b"), info, last)
		
		local facedir = node.param2
			local dir = minetest.facedir_to_dir(facedir)
		
		-- Y, -Y, X, -X, Z, -Z.
		
		local truth = {}
		local falsth = {}
		    if dir.x == 1 then truth[3] = true; falsth[4] = true
		elseif dir.x == -1 then truth[4] = true; falsth[3] = true
		elseif dir.z == 1 then truth[5] = true; falsth[6] = true
		elseif dir.z == -1 then truth[6] = true; falsth[5] = true end
		
		if type(a) == "table" then
			a = minetest.serialize(a) or a
		end
		if type(b) == "table" then
			b = minetest.serialize(b) or b
		end
		
		return unpack(a == b and {info, truth} or {info, falsth})
	end
})
minetest.register_node("rmod:scriptblock_guide", {
	description = "Scriptblock: One-Way Guide",
	tiles = {"rmod_scriptblock_guide_top.png", "rmod_scriptblock_guide_bottom.png",
		"rmod_scriptblock_guide_right.png", "rmod_scriptblock_guide_left.png",
		"rmod_scriptblock_guide_front.png", "rmod_scriptblock_guide_back.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	paramtype2 = "facedir",
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local facedir = node.param2
			local dir = minetest.facedir_to_dir(facedir)
		
		-- Y, -Y, X, -X, Z, -Z.
		
		local guide = {}
		    if dir.x == 1 then guide[3] = true
		elseif dir.x == -1 then guide[4] = true
		elseif dir.z == 1 then guide[5] = true
		elseif dir.z == -1 then guide[6] = true end
		
		return info, guide
	end
})

minetest.register_node("rmod:scriptblock_add", {
	description = "Scriptblock: Add",
	tiles = {"rmod_scriptblock_add.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[a;A;${a}]
field[b;B;${b}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.a) then
			minetest.get_meta(pos):set_string("a", fields.a)
		end
		if (fields.b) then
			minetest.get_meta(pos):set_string("b", fields.b)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local a = rmod.scriptblock.escape(meta:get_string("a"), info, last)
			local b = rmod.scriptblock.escape(meta:get_string("b"), info, last)
		
		local facedir = node.param2
			local dir = minetest.facedir_to_dir(facedir)
		
		return tostring((tonumber(a) or 0) + (tonumber(b) or 0))
	end
})
minetest.register_node("rmod:scriptblock_subtract", {
	description = "Scriptblock: Subtract",
	tiles = {"rmod_scriptblock_subtract.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[a;A;${a}]
field[b;B;${b}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.a) then
			minetest.get_meta(pos):set_string("a", fields.a)
		end
		if (fields.b) then
			minetest.get_meta(pos):set_string("b", fields.b)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local a = rmod.scriptblock.escape(meta:get_string("a"), info, last)
			local b = rmod.scriptblock.escape(meta:get_string("b"), info, last)
		
		local facedir = node.param2
			local dir = minetest.facedir_to_dir(facedir)
		
		return tostring((tonumber(a) or 0) - (tonumber(b) or 0))
	end
})
minetest.register_node("rmod:scriptblock_multiply", {
	description = "Scriptblock: Multiply",
	tiles = {"rmod_scriptblock_multiply.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[a;A;${a}]
field[b;B;${b}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.a) then
			minetest.get_meta(pos):set_string("a", fields.a)
		end
		if (fields.b) then
			minetest.get_meta(pos):set_string("b", fields.b)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local a = rmod.scriptblock.escape(meta:get_string("a"), info, last)
			local b = rmod.scriptblock.escape(meta:get_string("b"), info, last)
		
		local facedir = node.param2
			local dir = minetest.facedir_to_dir(facedir)
		
		return tostring((tonumber(a) or 0) * (tonumber(b) or 0))
	end
})
minetest.register_node("rmod:scriptblock_divide", {
	description = "Scriptblock: Divide",
	tiles = {"rmod_scriptblock_divide.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[a;A;${a}]
field[b;B;${b}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.a) then
			minetest.get_meta(pos):set_string("a", fields.a)
		end
		if (fields.b) then
			minetest.get_meta(pos):set_string("b", fields.b)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local a = rmod.scriptblock.escape(meta:get_string("a"), info, last)
			local b = rmod.scriptblock.escape(meta:get_string("b"), info, last)
		
		local facedir = node.param2
			local dir = minetest.facedir_to_dir(facedir)
		
		return tostring((tonumber(a) or 0) / (tonumber(b) or 0))
	end
})

minetest.register_node("rmod:scriptblock_player_detector", {
	description = "Scriptblock: Player Detector",
	tiles = {"rmod_scriptblock_player_detector.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local players = minetest.get_connected_players()
		
		local nearest = nil
		local min_distance = math.huge
		for index, player in pairs(players) do
			local distance = vector.distance(pos, player:getpos())
			if distance < min_distance then
				min_distance = distance
				nearest = player:get_player_name()
			end
		end
		
		return nearest or ""
	end
})



minetest.register_node("rmod:scriptblock_set_attribute", {
	description = "Scriptblock: Set Attribute of Object",
	tiles = {"rmod_scriptblock_set_attribute.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[propname;Attribute Name;${propname}]
field[value;Value;${value}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.propname) then
			minetest.get_meta(pos):set_string("propname", fields.propname)
		end
		if (fields.value) then
			minetest.get_meta(pos):set_string("value", fields.value)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local propname = rmod.scriptblock.escape(meta:get_string("propname"), info, last)
			local value = rmod.scriptblock.escape(meta:get_string("value"), info, last)
		
		if type(info) ~= "table" then
			if type(info) == "string" then
				local deserialized = minetest.deserialize(info)
				if deserialized then info = deserialized else return info end
			else
				return info
			end
		end
		
		-- We want to avoid problems like this:
		-- serialize({nest = serialize({table})) =/= serialize({nest = {table}})
		-- so we automatically deserialize the value if it can be deserialized.
		if type(value) == "string" then
			local deserialized = minetest.deserialize(value)
			if deserialized then value = deserialized end
		end
		
		info[propname] = value
		
		return info
	end
})
minetest.register_node("rmod:scriptblock_get_attribute", {
	description = "Scriptblock: Get Attribute of Object",
	tiles = {"rmod_scriptblock_get_attribute.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[propname;Attribute Name;${propname}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.propname) then
			minetest.get_meta(pos):set_string("propname", fields.propname)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		local meta = minetest.get_meta(pos)
			local propname = rmod.scriptblock.escape(meta:get_string("propname"), info, last)
		
		if type(info) ~= "table" then
			if type(info) == "string" then
				local deserialized = minetest.deserialize(info)
				if deserialized then info = deserialized else return info end
			else
				return info
			end
		end
		
		return info[propname]
	end
})
minetest.register_node("rmod:scriptblock_new_object", {
	description = "Scriptblock: New Object",
	tiles = {"rmod_scriptblock_new_object.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		return {}
	end
})



minetest.register_node("rmod:scriptblock_digiline", {
	description = "Scriptblock: Digiline Receiver",
	tiles = {"rmod_scriptblock_digiline.png"},
	groups = {oddly_breakable_by_hand = 1},
	use_texture_alpha = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", [[
field[progchannel;]] .. program_channel .. [[;${progchannel}]
field[digichannel;Digiline channel;${digichannel}]
]])
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local name = sender:get_player_name()
		if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, name)
			return
		end
		if (fields.digichannel) then
			minetest.get_meta(pos):set_string("digichannel", fields.digichannel)
		end
		if (fields.progchannel) then
			minetest.get_meta(pos):set_string("progchannel", fields.progchannel)
		end
	end,
	scriptblock = function (pos, node, sender, info, last, main_channel)
		return info
	end,
	digiline = {
		receptor = {},
		effector = {
		action = function (pos, node, msgchannel, msg)
			local meta = minetest.get_meta(pos)
				local progchannel = meta:get_string("progchannel")
				local digichannel = meta:get_string("digichannel")
			
			if msgchannel ~= digichannel then debug("WRONG CHANNEL"); return end
			
			debug("ACTIVATED")
			table.insert(queue, {pos, pos, minetest.serialize(msg) or msg or "", "", progchannel or ""})
		end,
	}}
})
