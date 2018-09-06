--
-- Scriptblocks - Digilines
--

-- Digiline receivers
scriptblocks.register_with_alias('digiline_receiver', {
    description = 'Scriptblocks: Digiline Receiver',
    tiles = {'scriptblocks_digiline.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[channel;]] .. scriptblocks.program_channel .. [[;${channel}]
field[digichannel;Digiline channel;${digichannel}]
]])
    end,
    on_receive_fields = scriptblocks.create_formspec_handler(
        false, 'channel', 'digichannel'
    ),
    scriptblock = function (pos, node, sender, info, last, main_channel)
        return
    end,
    digiline = {
        receptor = {},
        effector = {
        action = function (pos, node, msgchannel, msg)
            local meta = minetest.get_meta(pos)
                local progchannel = meta:get_string('channel')
                local digichannel = meta:get_string('digichannel')
            
            if msgchannel ~= digichannel then return end
            
            scriptblocks.queue(pos, pos, msg, '', progchannel or '')
        end,
    }}
})

-- Digiline senders
scriptblocks.register_with_alias('digiline_sender', {
    description = 'Scriptblocks: Digiline Sender',
    tiles = {'scriptblocks_digiline_sender.png'},
    groups = {oddly_breakable_by_hand = 1},
    use_texture_alpha = true,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('formspec', [[
field[channel;Digiline channel;${channel}]
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
    end,
    scriptblock = function (pos, node, sender, info, last, main_channel)
        if not digiline then return end
        local meta = minetest.get_meta(pos)
            local channel = meta:get_string('channel')
        
        digiline:receptor_send(pos, digiline.rules.default, channel, info)
        return
    end,
    digiline = {
        receptor = {},
        effector = {action = function (pos, node, msgchannel, msg)
        end,}
    }
})

-- Legacy rmod alias
minetest.register_alias_force('rmod:scriptblock_digiline',
    'scriptblocks:digiline_receiver')
