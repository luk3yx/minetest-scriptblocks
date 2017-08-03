local modpath = minetest.get_modpath("rmod")

dofile(modpath .. "/grate.lua")
dofile(modpath .. "/conveyor.lua")
dofile(modpath .. "/crate.lua")

if minetest.get_modpath("mesecons") then 
	dofile(modpath .. "/meseconveyor.lua")
end
if minetest.get_modpath("digilines") then 
	dofile(modpath .. "/digiconveyor.lua")
end
