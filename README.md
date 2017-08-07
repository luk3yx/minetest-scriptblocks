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

### An important note

Scriptblocks can handle values of various types, such as objects (tables), strings, numbers and booleans. Recent changes mean that scriptblocks no longer convert between them when it is unnecessary. As a result, attempting to compare the equality of, say, a boolean with the string "true" will result in false, because a boolean is not a string. Please keep this in mind as you program with scriptblocks, to avoid messy coding (building? :P) and frustration.

### Basics

When the Mesecon Receiver scriptblock (which is yellow with an exclamation mark on it) receives mesecon power, it triggers any scriptblocks adjacent to it. Each scriptblock will then trigger each scriptblock adjacent to itself (excluding the one that triggered it in the first place).

### Variables

You can store data in these scripts with the SET (looks like :=) and GET (looks like []) blocks. Each script can keep track of up to two values during execution (@info and @last), and the GET block will update @last to the previous @info, while updating @info to the value of the chosen variable. All scriptblock inputs may have "@info" or "@last" written inside them, which will be substituted for the corresponding values at runtime.

@last usually updates to the previous @info when @info gets changed, however there are exceptions for when the change is small (e.g. SET ATTRIBUTE OF OBJECT and the NOT gate).

### Program channels

Program channels are channels you can set to avoid clashing with other programs that may use similar or equal variable names. You can still set the variables of other channels by entering them into SET and GET variable blocks.

### Mathematical operators

The mathematical operators (add, subtract, multiply, divide) work in much the same way as GET - they update @last to the previous @info, and update @info to the result of the calculation. To add two values together, you would do (or rather, build) something along the lines of "GET a; GET b; ADD @last @info; SET c @info;", which will set c to the sum of a and b.

### Booleans

There are comparison operators which will return true or false depending on whether their condition is true. For example, a "LESS THAN" block with A = 3 and B = 2 will return false, while one with A = 1 instead will return true. Booleans themselves can be manipulated with NOT (turns false into true and vice versa), AND (only true if both operands are true) and OR (only false if both operands are false).

Note that in the case of AND and OR, the two operands are taken to be @info and @last respectively, since they are expected to be booleans - and being able to input "true" or "false" directly into one doesn't make sense to me (what's the point of "true OR x" or "false AND y"?).

### Conditional

The teal "?" block will lend execution towards the green side if the value reaching it (@info) is non-nil, and non-false. If it /is/ nil or false, execution is lent towards the red side instead. Formerly this took two operands and compared them, but that functionality has been replaced by the comparison operators described above.

### Print

The purple blocks with a speech bubble on them will print the message specified inside to the chat. If the player name is left empty, the message is sent to everyone - otherwise, it is sent to that player.

### Guide

The grey blocks which look like three arrows that converge into one are guides - they are used to aid looping by funnelling all execution in one direction - never will a guide execute nearby blocks other than the one it is pointing to.

### Player Detector

The blue block with the simplified logo of a player avatar is the Player Detector. When it is ran, it updates @last to the previous @info and updates @info to the name of the nearest player.

### Objects

The bright cyan blocks (GET ATTRIBUTE OF OBJECT, SET ATTRIBUTE OF OBJECT, and NEW OBJECT) can be used to create complex objects, modify and get their attributes.

### Digiline Receiver

These are pastel blue equivalents to the Mesecon Detectors, and will trigger adjacent scriptblocks when a digiline message with the specified digiline channel is received. The information contained in the message is stored in @info, so that you can store it in a program variable. If the information is in the form of a table, you can modify it with the object blocks described earlier.

### Digiline Sender

These are the polar opposites of the Digiline Receivers - they will send the data contained in @info on the specified channel.
