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
    on_receive_fields = function(pos, formname, fields, sender)
        local name = sender:get_player_name()
        if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
            minetest.record_protection_violation(pos, name)
            return
        end
        if (fields.channel) then
            minetest.get_meta(pos):set_string('channel', fields.channel)
        end
        if (fields.info) then
            minetest.get_meta(pos):set_string('info', fields.info)
        end
    end,
    scriptblock = function (pos, node, sender, info, last, main_channel)
        return
    end,
    mesecons = {effector = {
        action_on = function (pos, node)
            local meta = minetest.get_meta(pos)
                local channel = meta:get_string('channel')
                local info = meta:get_string('info')
            
            scriptblocks.queue(pos, pos, info or '', '', channel or '')
        end,
    }}
})

-- Legacy rmod alias
minetest.register_alias_force('rmod:scriptblock_mesecon',
    'scriptblocks:mesecon_receiver')
