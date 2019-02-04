--
-- Minetest scriptblock mod - Scriptblocks
--

scriptblocks.program_channel = 'Program channel'

local a_b_formspec_handler = scriptblocks.create_formspec_handler(
    false, 'a', 'b'
)

scriptblocks.register_with_alias('set', {
    description = 'Scriptblocks: Set',
    tiles = {'scriptblocks_set.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[channel;]] .. scriptblocks.program_channel .. [[ (optional);${channel}]
field[varname;Varname;${varname}]
field[value;Value;${value}]
]])
    end,

    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'channel', 'varname', 'value'
    ),

    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local channel = scriptblocks.escape(meta:get_string('channel'), info, last)
            local varname = scriptblocks.escape(meta:get_string('varname'), info, last)
            local value = scriptblocks.escape(meta:get_string('value'), info, last)

        local store = scriptblocks.get_storage()

        if channel == '' or not channel then channel = main_channel end

        if not varname then varname = '' end

        if not store[channel] then store[channel] = {} end
        store[channel][varname] = value

        scriptblocks.set_storage(store)

        return
    end
})
scriptblocks.register_with_alias('get', {
    description = 'Scriptblocks: Get',
    tiles = {'scriptblocks_get.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[channel;]] .. scriptblocks.program_channel .. [[ (optional);${channel}]
field[varname;Varname;${varname}]
]])
    end,

    on_receive_fields = scriptblocks.create_formspec_handler(
        true, 'channel', 'varname'
    ),

    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local channel = scriptblocks.escape(meta:get_string('channel'), info, last)
            local varname = scriptblocks.escape(meta:get_string('varname'), info, last)

        local store = scriptblocks.get_storage()

        if channel == '' or not channel then channel = main_channel end
        if not varname then return end

        if not store[channel] then store[channel] = {} end

        return store[channel][varname]
    end
})

scriptblocks.register_with_alias('print', {
    description = 'Scriptblocks: Print',
    tiles = {'scriptblocks_print.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[player;Player (optional);${player}]
field[message;Message;${message}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'player', 'message'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local plr = scriptblocks.escape(meta:get_string('player'), info, last)
            local msg = scriptblocks.escape(meta:get_string('message'), info, last)

        if not plr then return end
        if not msg then return end

        if type(msg) == 'table' then msg = scriptblocks.stringify(msg) end

        if plr == '' then
            minetest.chat_send_all('Scriptblock -> all: ' .. tostring(msg))
        else
            minetest.chat_send_player(plr, 'Scriptblock -> you: ' .. tostring(msg))
        end

        return
    end
})
scriptblocks.register_with_alias('if', {
    description = 'Scriptblocks: If',
    tiles = {'scriptblocks_if_top.png', 'scriptblocks_if_bottom.png',
        'scriptblocks_if_right.png', 'scriptblocks_if_left.png',
        'scriptblocks_if_truth.png', 'scriptblocks_if_falsth.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    paramtype2 = 'facedir',
    scriptblock = function(pos, node, sender, info, last, main_channel)
        -- compatibility for back when this was 'IF EQUALS'
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        -- Y, -Y, X, -X, Z, -Z.

        local truth = {}
        local falsth = {}
            if dir.x == 1 then truth[3] = true; falsth[4] = true
        elseif dir.x == -1 then truth[4] = true; falsth[3] = true
        elseif dir.z == 1 then truth[5] = true; falsth[6] = true
        elseif dir.z == -1 then truth[6] = true; falsth[5] = true end

        --[[if type(a) == 'table' then
            a = scriptblocks.stringify(a) or a
        end
        if type(b) == 'table' then
            b = scriptblocks.stringify(b) or b
        end]]

        if a == '' and b == '' then
            return unpack(info and {nil, truth} or {nil, falsth})
        else
            return unpack(scriptblocks.compare(a, b) and {nil, truth} or {nil, falsth})
        end
    end
})
scriptblocks.register_with_alias('guide', {
    description = 'Scriptblocks: One-Way Guide',
    tiles = {'scriptblocks_guide_top.png', 'scriptblocks_guide_bottom.png',
        'scriptblocks_guide_right.png', 'scriptblocks_guide_left.png',
        'scriptblocks_guide_front.png', 'scriptblocks_guide_back.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    paramtype2 = 'facedir',
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        -- Y, -Y, X, -X, Z, -Z.

        local guide = {}
            if dir.x == 1 then guide[3] = true
        elseif dir.x == -1 then guide[4] = true
        elseif dir.z == 1 then guide[5] = true
        elseif dir.z == -1 then guide[6] = true end

        return nil, guide
    end
})

scriptblocks.register_with_alias('add', {
    description = 'Scriptblocks: Add',
    tiles = {'scriptblocks_add.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,
    on_receive_fields = a_b_formspec_handler,

    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        return (tonumber(a) or 0) + (tonumber(b) or 0)
    end
})
scriptblocks.register_with_alias('subtract', {
    description = 'Scriptblocks: Subtract',
    tiles = {'scriptblocks_subtract.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,
    on_receive_fields = a_b_formspec_handler,

    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        return (tonumber(a) or 0) - (tonumber(b) or 0)
    end
})
scriptblocks.register_with_alias('multiply', {
    description = 'Scriptblocks: Multiply',
    tiles = {'scriptblocks_multiply.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,
    on_receive_fields = a_b_formspec_handler,

    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        return (tonumber(a) or 0) * (tonumber(b) or 0)
    end
})
scriptblocks.register_with_alias('divide', {
    description = 'Scriptblocks: Divide',
    tiles = {'scriptblocks_divide.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,on_receive_fields = a_b_formspec_handler,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        return (tonumber(a) or 0) / (tonumber(b) or 0)
    end
})
scriptblocks.register_with_alias('modulo', {
    description = 'Scriptblocks: Modulo',
    tiles = {'scriptblocks_modulo.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,on_receive_fields = a_b_formspec_handler,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        local facedir = node.param2
            local dir = minetest.facedir_to_dir(facedir)

        return (tonumber(a) or 0) % (tonumber(b) or 0)
    end
})

scriptblocks.register_with_alias('player_detector', {
    description = 'Scriptblocks: Player Detector',
    tiles = {'scriptblocks_player_detector.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local players = minetest.get_connected_players()

        local nearest = nil
        local min_distance = math.huge
        for index, player in pairs(players) do
            local distance = vector.distance(pos, player:get_pos())
            if distance < min_distance then
                min_distance = distance
                nearest = player:get_player_name()
            end
        end

        return nearest or ''
    end
})



scriptblocks.register_with_alias('set_attribute', {
    description = 'Scriptblocks: Set Attribute of Object',
    tiles = {'scriptblocks_set_attribute.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[propname;Attribute Name;${propname}]
field[value;Value;${value}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'propname', 'value'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local propname = scriptblocks.escape(meta:get_string('propname'), info, last)
            local value = scriptblocks.escape(meta:get_string('value'), info, last)

        if not propname then return end

        if type(info) ~= 'table' then
            --[[if type(info) == 'string' then
                local deserialized = minetest.deserialize(info)
                if deserialized then info = deserialized else return end
            else]]
                return
            --end
        end

        -- We want to avoid problems like this:
        -- serialize({nest = serialize({table})) =/= serialize({nest = {table}})
        -- so we automatically deserialize the value if it can be deserialized.
        --[[if type(value) == 'string' then
            local deserialized = minetest.deserialize(value)
            if deserialized then value = deserialized end
        end]]

        info[propname] = value

        return info
    end
})
scriptblocks.register_with_alias('get_attribute', {
    description = 'Scriptblocks: Get Attribute of Object',
    tiles = {'scriptblocks_get_attribute.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[propname;Attribute Name;${propname}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'propname'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local propname = scriptblocks.escape(meta:get_string('propname'), info, last)

        if not propname then return end

        if type(info) ~= 'table' then
            --[[if type(info) == 'string' then
                local deserialized = minetest.deserialize(info)
                if deserialized then info = deserialized else return end
            else]]
                return
            --end
        end

        return info[propname]
    end
})
scriptblocks.register_with_alias('new_object', {
    description = 'Scriptblocks: New Object',
    tiles = {'scriptblocks_new_object.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        return {}
    end
})

scriptblocks.register_with_alias('not', {
    description = 'Scriptblocks: Not Gate',
    tiles = {'scriptblocks_not.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        return not info
    end,
})
scriptblocks.register_with_alias('and', {
    description = 'Scriptblocks: And Gate',
    tiles = {'scriptblocks_and.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        return info and last
    end,
})
scriptblocks.register_with_alias('or', {
    description = 'Scriptblocks: Or Gate',
    tiles = {'scriptblocks_or.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        return info or last
    end,
})

scriptblocks.register_with_alias('equals', {
    description = 'Scriptblocks: Equals',
    tiles = {'scriptblocks_equals.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,on_receive_fields = a_b_formspec_handler,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        return scriptblocks.compare(a, b)
    end,
})
scriptblocks.register_with_alias('lt', {
    description = 'Scriptblocks: Less than',
    tiles = {'scriptblocks_lt.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,on_receive_fields = a_b_formspec_handler,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        return (tonumber(a) or 0) < (tonumber(b) or 0)
    end,
})
scriptblocks.register_with_alias('gt', {
    description = 'Scriptblocks: Greater than',
    tiles = {'scriptblocks_gt.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[a;A;${a}]
field[b;B;${b}]
]])
    end,on_receive_fields = a_b_formspec_handler,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local a = scriptblocks.escape(meta:get_string('a'), info, last)
            local b = scriptblocks.escape(meta:get_string('b'), info, last)

        return (tonumber(a) or 0) > (tonumber(b) or 0)
    end,
})



scriptblocks.register_with_alias('type', {
    description = 'Scriptblocks: Get Type',
    tiles = {'scriptblocks_type.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    scriptblock = function(pos, node, sender, info, last, main_channel)
        return type(info) == 'table' and 'object' or type(info)
    end,
})
scriptblocks.register_with_alias('number', {
    description = 'Scriptblocks: Number Literal',
    tiles = {'scriptblocks_number.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[number;Number literal;${number}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'number'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local number = meta:get_string('number')

        return tonumber(number)
    end,
})
scriptblocks.register_with_alias('string', {
    description = 'Scriptblocks: String Literal',
    tiles = {'scriptblocks_string.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[str;String literal;${str}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'str'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
            local str = meta:get_string('str')

        return str
    end,
})
