Rolls for loot in World of Warcraft.  Stormwardens makes use of a form of Roll-for-interest system that calls for both need and greed rolls, with each member being allowed one 'priority' need roll per instance.  This addon keeps track of which members have used their needs, and automates the basic roll system.

# Release Notes #
The current release ([r76](https://code.google.com/p/swloot/source/detail?r=76)) removes the raid roll functionality.  This has been moved to OpenRolls (also a featured download).  The general interface remains largely unchanged.

# Rudimentary Documentation #
All tasks are handled via the command line.

## Initial Set up ##
`/swloot raid start <NAME>`

This command begins tracking the raid 

&lt;NAME&gt;

.  

&lt;NAME&gt;

 must be unique and is case sensitive.  If 

&lt;NAME&gt;

 is omitted, will resume tracking the last known raid.

`/swloot raid stop`

Stops tracking the raid.

## Rolling Loot ##
`/swloot roll <ITEM>`

`/swloot award`

Line one starts the roll. Line two awards the loot to whoever the mod believes won the roll. You provide an actual item link (as gotten by shift-clicking the item in the loot window); actual names of items without a link are rejected.

## Graphical Interface ##
When you loot an item at or above the current loot threshold, a series of windows will also open providing an interface to the above functions.  "Need" and "Greed" begin rolls for the specified loot, the results of which are filled in automatically.  The returned values can be changed manually if so desired.  Clicking "Award" actually awards the item.

Each item maintains its own winner, so rolling multiple items do not clear previous winners like happens when using the command line interface.  However, this information is lost when the loot window closes.

## Advanced functions ##
`/swloot loot direct <NAME> <ITEM> <USED NEED>`

Used if the mod is wrong for whatever reason, so you can circumvent the roll mechanism all together. The last option is need/greed; if omitted, a need is not used.

`/swloot loot need <NAME> <USE NEED>`

Used if somebody rolled need, but you decided to grant it as a greed roll. Or vice versa.  <USE NEED> is true/false; if true, 

&lt;NAME&gt;

's need roll is taken away.  If false, the need is given back.  If omitted, the status toggles.

`/swloot greed <ITEM>`

Used if you want to skip the need portion of the roll. Still only provides a 5-second roll window.

`/swloot loot disqualify <NAME>`

Used to disqualify a specific roller.  If performed while a roll is taking place, the addon will behave as normal and 'award' can be used.  If the roll has finished, the new winner will be printed to chat, but 'loot direct' must be used to award the loot as 'award' will not be sure how to behave.

`/swloot summarize`

Prints details for the current raid to the chat. Details include all loot awarded by the addon (via either 'award' or 'loot direct'...loot distributed via raid rolls et cetera are not tracked), and which players have used needs.

## Synchronization ##

`/swloot synchronize <NAME> <RAID>`

Sends your loot information to another player. This communication is bidirectional, such that afterwards both player's will have the same information.  You must be on 

&lt;NAME&gt;

's trusted list (see below) to synchronize.  

&lt;NAME&gt;

 does not need to be on your own trusted list.

`/swloot trusted add <NAME>`

`/swloot trusted remove <NAME>`

Controls who you will synchronize with. Synchronization requests from players not on this list will be ignored.

## Debug Functionality ##

`/swloot debug verbose`

Toggles printing of additional information when performing raid summaries.

`/swloot debug summarize`

Prints a summary that only you can see

`/swloot debug output <LEVEL>`

Controls who can see output from the addon.  

&lt;LEVEL&gt;

 can be "Raid", "Party", or "Chat".  "Raid" is the default value and results in everybody seeing the information; "Party" limits it to members of your own party; "Chat" limits it to just your screen.  Note that this only modifies public information; data that would normally be private remains private regardless of this value.