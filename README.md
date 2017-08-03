# rmod
RMod mod for Minetest with various cool nodes.

Conveyors
-

Conveyors are nodes that can carry entities, such as players and items. There are a few bugs with it, but it works fine for the most part.

Meseconveyors
-

Meseconveyors are conveyors which can be activated and deactivated with mesecons.

Digiconveyors
-

Digiconveyors can not only be turned on and off with digilines, but they can also be reversed (which flips their facing direction). The messages available at the moment are "on", "off", "toggle" (functions as both "on" and "off"), "reverse" (inverts the direction), "left" (turns left 90 degrees) and "right".

Crates
-

Crates are like chests, but you can pick them up with the items inside. As a result, you can also stack crates indefinitely.

Grates
-

Grates are nodes which let water flow through, but not players or items.

Mesegrates
-

Mesegrates are self-explanatory - power them, and they let liquids flow.

Digigrates
-

Digigrates can be adjusted by sending messages - they include "on", "off", "toggle" and "set". That last one, "set", is sent as a table {command = "sent", value = x}, substituting x for the percentage of water you want to pass through (although, tbh, it's more complicated than that).
