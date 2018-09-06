# Scriptblocks

A RMod fork that removes everything except scriptblocks, and adds to
scriptblocks and makes them more efficient.

## RMod compatibility

The scriptblocks mod aims to keep backwards compatibility with rmod, so servers
that used to use or are even still using rmod will face no issues when changing
to scriptblocks. However, moving back from scriptblocks to rmod will void all
existing scriptblocks. Any complex scriptblocks machine (over 30 nodes long)
will be "cut off" by the new anti-denial-of-service system.

### Known issues when "upgrading" from rmod

- If your script isn't using a program name, there is a possibility that
  variables will be lost because of program naming scheme changes.

## What are scriptblocks?

Scriptblocks are blocks that you can use for creating simple programs. They are
one of the most complicated parts of rmod, which can be a good thing or a bad
thing depending on your viewpoint.

### An important note

Scriptblocks can handle values of various types, such as objects (tables),
strings, numbers and booleans. Recent changes mean that scriptblocks no longer
convert between them when it is unnecessary. As a result, attempting to compare
the equality of, say, a boolean with the string "true" will result in false,
because a boolean is not a string. Please keep this in mind as you program with
scriptblocks, to avoid messy coding (or building) and frustration.

Any scriptblocks script over 30 nodes long will be "cut off" to prevent infinite
loops.

## How to use scriptblocks

### Basics

When the Mesecon Receiver scriptblock (which is yellow with an exclamation mark
on it) receives mesecon power, it triggers any scriptblocks adjacent to it. Each
scriptblock will then trigger each scriptblock adjacent to itself (excluding the
one that triggered it in the first place).

### Variables

You can store data in these scripts with the SET (looks like :=) and GET
(looks like []) blocks. Each script can keep track of up to two values during
execution (@info and @last), and the GET block will update @last to the previous
@info, while updating @info to the value of the chosen variable. All scriptblock
inputs may have `@info` or `@last` written inside them, which will be
substituted for the corresponding values at runtime.

When data is pushed to `@info`, `@last` is updated to the previous @info. In
this manner, the system is like a stack with extremely low memory - it will only
store the two most recent items of the stack.

### Program channels

Program channels are channels you can set to share and/or avoid clashing with
other programs that may use similar or equal variable names. You can still set
the variables of other channels by entering them into SET and GET variable
blocks.

Channel names can be protected the same way pipeworks teleportation tubes can.
The channel `player:test` can only be accessed by `player`, however
`player;test` can be read by anyone but only written to by `player`.

If the program channel is unspecified, it will be set to the channel in the
mesecons/digilines receiver, and if that is empty, to a protected channel
owned by the server containing the co-ordinates.

### Mathematical operations

The mathematical operations (add, subtract, multiply, divide) work in much the
same way as GET - they update @last to the previous @info, and update @info to
the result of the calculation. To add two values together, you would do (or
rather, build) something along the lines of
`GET a; GET b; ADD @last @info; SET c @info;`, which will set c to the sum of
a and b.

### Booleans

There are comparison operators which will return true or false depending on
whether their condition is true. For example, a "LESS THAN" block with A = 3
and B = 2 will return false, while one with A = 1 instead will return true.
Booleans themselves can be manipulated with NOT (turns false into true and vice
versa), AND (only true if both operands are true) and OR (only false if both
operands are false).

Note that in the case of AND and OR, the two operands are taken to be @info and
@last respectively, since they are expected to be booleans - and being able to
input `true` or `false` directly into one doesn't make sense (what's the
point of `true OR x` or `false AND y`?).

### Conditional

The teal "?" block will lend execution towards the green side if the value
reaching it (@info) is non-nil, and non-false. If it /is/ nil or false,
execution is lent towards the red side instead. Formerly this took two operands
and compared them, but that functionality has been replaced by the comparison
operators described above.

### Print

The purple blocks with a speech bubble on them will print the message specified
inside to the chat. If the player name is left empty, the message is sent to
everyone - otherwise, it is sent to that player.

### Guide

The grey blocks which look like three arrows that converge into one are guides -
they are used to aid looping by funnelling all execution in one direction -
never will a guide execute nearby blocks other than the one it is pointing to.

### Player Detector

The blue block with the simplified logo of a player avatar is the Player
Detector. When it is run, it updates @last to the previous @info and updates
@info to the name of the nearest player.

### Objects

The bright cyan blocks (GET ATTRIBUTE OF OBJECT, SET ATTRIBUTE OF OBJECT, and
NEW OBJECT) can be used to create complex objects, modify and get their
attributes.

### Digiline Receiver

These are pastel blue equivalents to the Mesecon Detectors, and will trigger
adjacent scriptblocks when a digiline message with the specified digiline
channel is received. The information contained in the message is stored in
@info, so that you can store it in a program variable. If the information is in
the form of a table, you can modify it with the object blocks described earlier.

### Digiline Sender

These are the polar opposites of the Digiline Receivers - they will send the
data contained in @info on the specified channel.

### Type blocks

The type blocks deal with the basic types of the system - strings, numbers,
booleans, and tables (called objects in this mod). You can use the GET TYPE
block to get the type of the current @info, and you can use the NUMBER LITERAL
and STRING LITERAL blocks to set @info to a set value (even the string "@info"
itself - the automatic substitution system isn't applied here).
