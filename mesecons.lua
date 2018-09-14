--
-- Scriptblocks - Mesecons
--

-- Mesecon receiver
scriptblocks.register_with_alias('mesecon_receiver', {
    description = 'Scriptblocks: Mesecon Receiver',
    tiles = {'scriptblocks_mesecon.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[channel;]] .. scriptblocks.program_channel .. [[;${channel}]
field[info;Starting @info;${info}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'channel', 'info'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        return
    end,
    mesecons = {effector = {
        action_on = function(pos, node)
            local meta = minetest.get_meta(pos)
                local channel = meta:get_string('channel')
                local info = meta:get_string('info')

            scriptblocks.queue(pos, pos, info or '', '', channel)
        end,
    }}
})

-- Mesecon sender
local get_rules = function(pos)
    local rules = {}
    for _, rule in ipairs(mesecon.rules.alldirs) do
        local rpos = vector.add(pos, rule)
        local node = minetest.get_node(rpos)
        local def  = node.name and minetest.registered_nodes[node.name]
        if def and not def.scriptblock then
            table.insert(rules, rule)
        end
    end
    return rules
end

local disable_sender = function(pos)
    if minetest.get_node(pos).name ~= 'scriptblocks:mesecon_sender_on' then
        return
    end
    minetest.swap_node(pos, {name = 'scriptblocks:mesecon_sender_off'})
    mesecon.receptor_off(pos, get_rules(pos))
end

mesecon.register_node('scriptblocks:mesecon_sender', {
    description = 'Scriptblocks: Mesecon Sender',
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('mode', tostring(scriptblocks.tick_delay + 0.15))
        meta:set_string('formspec', [[
field[mode;Pulse delay (0 to toggle, @info/@last for if);${mode}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'mode'
    ),
    scriptblock = function(pos, node, sender, info, last, main_channel)
        local meta = minetest.get_meta(pos)
        local mode = meta:get_string('mode')
        local cond = nil
        if mode == '0' then
            cond = mesecon.flipstate(pos, node) == 'on'
        elseif mode == '@info' then
            cond = info
        elseif mode == '@last' then
            cond = last
        else
            cond = tonumber(mode)
        end

        if type(cond) == 'number' then
            local delay = cond
            cond = true
            if type(delay) ~= 'number' or
              not (delay > scriptblocks.tick_delay) then
                -- Catch nil, NaN and small numbers
                delay = 0.1
            elseif delay > 5 then
                -- Catch large numbers and inf
                delay = 5
            end
            minetest.after(delay, disable_sender, pos)
        end

        if cond ~= nil then
            local state
            if cond then
                state = 'on'
            else
                state = 'off'
            end
            minetest.swap_node(pos, {
                name = 'scriptblocks:mesecon_sender_' .. state,
            })
            mesecon['receptor_' .. state](pos, get_rules(pos))
        end
    end,
}, {
    groups = {oddly_breakable_by_hand = 1},
    tiles = {'scriptblocks_mesecon_sender.png'},
    mesecons = {receptor = {
        state = mesecon.state.off,
        rules = mesecon.rules.allfaces,
    }}
}, {
    groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
    tiles = {'scriptblocks_mesecon_sender_on.png'},
    mesecons = {receptor = {
        state = mesecon.state.on,
        rules = mesecon.rules.allfaces,
    }}
})
minetest.register_alias('scriptblocks:mesecon_sender',
    'scriptblocks:mesecon_sender_off')

-- Legacy rmod alias
minetest.register_alias_force('rmod:scriptblock_mesecon',
    'scriptblocks:mesecon_receiver')
