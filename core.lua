--
-- Minetest scriptblocks mod - Core
--

--
-- scriptblock = function(pos, node, sender, info, last, main_channel)
--   'pos' and 'node' are the position and the node information of the
--      scriptblock being ran.
--   'sender' would be the position of the node responsible for activating it.
--   'info' is any information the previous node has sent to it.
--   'last' is the information that 'info' /was/ before it was last changed.
--   'channel' is the channel in which variables are stored.
--
--        <insert function code here>
--
--   return new_info, faces 
--   Information to pass to the next node(s), and information on which adjacent
--      spaces we should even try to signal to. This return statement is
--      optional and can be omitted entirely.
-- end

-- Original rmod functions
scriptblocks.stringify = function(t)
    if type(t) ~= 'table' then return tostring(t) end
    return minetest.serialize(t):sub(('return '):len()+1, -1)
end

scriptblocks.compare = function(a, b)
    -- Compare two tables by comparing their values -
    -- also make sure to support nested tables.
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    
    for i,j in pairs(a) do
        if not compare(j, b[i]) then return false end
    end
    for i,j in pairs(b) do
        if not compare(j, a[i]) then return false end
    end
    
    return true
end

-- TODO: Replace these functions with better ones
scriptblocks.get_storage = function()
    return minetest.deserialize(
        scriptblocks.storage:get_string('scriptblock')
    ) or {}
end
scriptblocks.set_storage = function(data)
    return scriptblocks.storage:set_string('scriptblock', minetest.serialize(data))
end

-- Is the channel reserved for another user?
scriptblocks.check_channel = function(name, channel, readonly)
    -- Channel name RegEx from https://github.com/minetest-mods/pipeworks
    -- Possibly(?) licensed under the GNU LGPL 2.1
    local victim, sep = channel:match('^([^:;]+)([:;])')
    if victim and sep then
        local valid = victim == name
        if victim ~= name and (sep ~= ';' or not readonly) then
            minetest.chat_send_player(name, 'Sorry, only ' .. victim ..
                ' may use that channel.')
            return true
        end
    end
    return false
end

-- Is the node protected?
scriptblocks.check_protection = function(pos, name, channel, readonly)
    if type(name) ~= 'string' then
        name = name:get_player_name()
    end
    
    if minetest.is_protected(pos, name) and
      not minetest.check_player_privs(name, {protection_bypass=true}) then
        minetest.record_protection_violation(pos, name)
        return true
    end
    
    if channel then
        return scriptblocks.check_channel(name, channel, readonly)
    end
    
    return false
end

-- To avoid lag and stack overflows, we add the data to a queue and then execute it with a globalstep.
local queue = {}
local queue_lock = false

-- Directly execute a scriptblock and return a queue with more scriptblocks
scriptblocks.run = function(pos, sender, info, last, channel, executions)
    local local_queue = {}
    
    if executions == nil then
        executions = scriptblocks.max_length
    elseif executions <= 0 then
        return
    end
    
    -- Get information about this script block we are told to execute.
    local node = minetest.get_node(pos)
        local name = node.name
            local def = minetest.registered_nodes[name]
    
    -- If the block is a script block...
    if def and def.scriptblock then
        local new_info, faces = def.scriptblock(pos, node, sender, info, last, channel)
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
                        local new_last
                        if new_info ~= nil then  -- If something has been pushed to the stack, 
                            new_last = info  -- we update @last.
                        else
                            new_info = info  -- Why bother updating it?
                            new_last = last
                        end
                        table.insert(local_queue, { new_pos, pos, new_info,
                            new_last, channel, executions - 1 })
                    end
                end
            end
        end
    end
    return local_queue
end

-- Escape text
scriptblocks.escape = function(text, info, last)
    local info = tostring(info or '')
    local last = tostring(last or '')
    
    if text == '@info' then return info end
    if text == '@last' then return last end
    
    if type(info) == 'table' then info = scriptblocks.stringify(info) or '' end
    if type(last) == 'table' then last = scriptblocks.stringify(last) or '' end
    return text and text:gsub('@info', info):gsub('@last', last)
end

-- Handle queued scriptblocks, but only when required.
local handle_queue
handle_queue = function()
    queue_lock = true
    local new_queue = {}
    for i, data in pairs(queue) do
        local new_list = scriptblocks.run(unpack(data))
        if new_list then
            for _,new_item in pairs(new_list) do
                table.insert(new_queue, new_item)
            end
        end
        
        if i > scriptblocks.max_per_step then
            break
        end
    end
    queue = new_queue
    
    if #queue > 0 then
        minetest.after(scriptblocks.tick_delay, handle_queue)
    else
        queue_lock = false
    end
end

-- Easily add items to the queue
scriptblocks.queue = function(pos, sender, info, last, channel)
    table.insert(queue, {pos, sender, info, last, channel})
    
    if not queue_lock then
        -- Start the queue handler
        handle_queue()
    end
end

-- A register with alias function to automatically add aliases
-- Uses register_alias_force() to unregister the original rmod one first.
scriptblocks.register_with_alias = function(name, def)
    local new_name = minetest.get_current_modname() .. ':' .. name
    minetest.register_node(new_name, def)
    minetest.register_alias_force('rmod:scriptblock_' .. name, new_name)
end

-- An easy(-ish) formspec handler
scriptblocks.create_formspec_handler = function(ro, ...)
    local names = {...}
    return function(pos, formname, fields, sender)
        if scriptblocks.check_protection(pos, sender, fields.channel, ro) then
            return
        end
        local meta = minetest.get_meta(pos)
        for _, i in ipairs(names) do
            if fields[i] then
                meta:set_string(i, fields[i])
            end
        end
    end
end
