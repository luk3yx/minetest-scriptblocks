rmod = {}  -- In case we need to allow other mods/files to access information.
local modpath = minetest.get_modpath("rmod")

dofile(modpath .. "/grate.lua")
dofile(modpath .. "/conveyor.lua")
dofile(modpath .. "/crate.lua")
dofile(modpath .. "/scriptblock.lua")

if minetest.get_modpath("mesecons") then 
	dofile(modpath .. "/meseconveyor.lua")
	dofile(modpath .. "/mesegrate.lua")
end
if minetest.get_modpath("digilines") then 
	dofile(modpath .. "/digiconveyor.lua")
	dofile(modpath .. "/digigrate.lua")
end
