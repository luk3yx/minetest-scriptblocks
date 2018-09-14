--
-- Minetest scriptblocks mod
--

-- Settings
scriptblocks = {
    -- The maximum length of scriptblocks scripts.
    max_length = 30,

    -- The maximum amount of scriptblocks processed during a globalstep
    max_per_step = 24,

    -- The "tick" delay - How long to wait between processing scriptblocks
    -- NOTE: If this is set too high, scriptblocks will appear unresponsive.
    tick_delay = 0.1,
}

-- Get the mod path and storage
local modpath = minetest.get_modpath('scriptblocks')
scriptblocks.storage = minetest.get_mod_storage()

-- Load scriptblocks lua files
dofile(modpath .. '/core.lua')
dofile(modpath .. '/scriptblock.lua')

-- Load mesecons and digilines scriptblocks
if minetest.get_modpath('mesecons') then
    dofile(modpath .. '/mesecons.lua')
end

if minetest.get_modpath('digilines') then
    dofile(modpath .. '/digilines.lua')
end

-- Override rmod scriptblock functions.
if minetest.get_modpath('rmod') then
    rmod.scriptblock = scriptblocks
end
