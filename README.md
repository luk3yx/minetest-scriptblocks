# rmod
RMod mod for Minetest with various cool nodes.

## Conveyors

Conveyors are nodes that can carry entities, such as players and items. There are a few bugs with it, but it works fine for the most part.

### Meseconveyors

Meseconveyors are conveyors which can be activated and deactivated with mesecons.

### Digiconveyors

Digiconveyors can not only be turned on and off with digilines, but they can also be reversed (which flips their facing direction). The messages available at the moment are "on", "off", "toggle" (functions as both "on" and "off"), "reverse" (inverts the direction), "left" (turns left 90 degrees) and "right".

## Crates

Crates are like chests, but you can pick them up with the items inside. As a result, you can also stack crates indefinitely.

## Grates

Grates are nodes which let water flow through, but not players or items.

### Mesegrates

Mesegrates are self-explanatory - power them, and they let liquids flow.

### Digigrates

Digigrates can be adjusted by sending messages - they include "on", "off", "toggle" and "set". That last one, "set", is sent as a table {command = "sent", value = x}, substituting x for the percentage of water you want to pass through (although, tbh, it's more complicated than that).

## Scriptblocks

Scriptblocks are blocks that you can use for creating simple programs. They are one of the most complicated parts of this mod, which can be a good thing or a bad thing depending on your viewpoint.

### Basics

When the Mesecon Detector scriptblock (which is yellow with an exclamation mark on it) receives mesecon power, it triggers any scriptblocks adjacent to it. Each scriptblock will then trigger each scriptblock adjacent to itself (excluding the one that triggered it in the first place).

### Variables

You can store data in these scripts with the SET (looks like :=) and GET (looks like []) blocks. Each script can keep track of up to two values during execution (@info and @last), and the GET block will update @last to the previous @info, while updating @info to the value of the chosen variable. All scriptblock inputs may have "@info" or "@last" written inside them, which will be substituted for the corresponding values at runtime.

### Program channels

Program channels are channels you can set to avoid clashing with other programs that may use similar or equal variable names. You can still set the variables of other channels by entering them into SET and GET variable blocks.

### Mathematical operators

The mathematical operators (add, subtract, multiply, divide) work in much the same way as GET - they update @last to the previous @info, and update @info to the result of the calculation. To add two values together, you would do (or rather, build) something along the lines of "GET a; GET b; ADD @last @info; SET c @info;", which will set c to the sum of a and b.

### Conditional

The teal "?" block will lend execution in one direction if the two input values are equal, and the other if they are not equal.

### Print

The purple blocks with a speech bubble on them will print the message specified inside to the chat.

### Guide

The grey blocks which look like three arrows that converge into one are guides - they are used to aid looping by funnelling all execution in one direction - never will a guide execute nearby blocks other than the one it is pointing to.
