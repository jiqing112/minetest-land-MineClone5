# MineClone 5

MineClone 5 is a fork of MineClone 2 with different workflow:
* No Minecraft version limitation, target version is Latest Java Edition
* Rapid delivery - small frequent releases with no milestones
* Merge by one approval - one other dev must approve the PR

Survive, gather, hunt, mine for ores, build houses, explore, and do much more.

### Gameplay
You start in a randomly-generated world made entirely of cubes. You can explore
the world and dig and build almost every block in the world to create new
structures. You can choose to play in a “survival mode” in which you have to
fight monsters and hunger for survival and slowly progress through the
various other aspects of the game, such as mining, farming, building machines, and so on
Or you can play in “creative mode” in which you can build almost anything instantly.

#### Gameplay summary

* Sandbox-style gameplay, no goals
* Survive: Fight against hostile monsters and hunger
* Mine for ores and other treasures
* Magic: Gain experience and enchant your tools
* Use the collected blocks to create great buildings, your imagination is the limit
* Collect flowers (and other dye sources) and colorize your world
* Find some seeds and start farming
* Find or craft one of hundreds of items
* Build a railway system and have fun with minecarts
* Build complex machines with redstone circuits
* In creative mode you can build almost anything for free and without limits

## How to play (quick start)
### Getting started
* **Punch a tree** trunk until it breaks and collect wood
* Place the **wood into the 2×2 grid** (your “crafting grid” in your inventory menu and craft 4 wood planks
* Place the 4 wood planks in a 2×2 shape in the crafting grid to **make a crafting table**
* **Rightclick the crafting table** for a 3×3 crafting grid to craft more complex things
* Use the **crafting guide** (book icon) to learn all the possible crafting recipes
* **Craft a wooden pickaxe** so you can dig stone
* Different tools break different kinds of blocks. Try them out!
* Continue playing as you wish. Have fun!

### Farming
* Find seeds
* Craft hoe
* Rightclick dirt or similar block with hoe to create farmland
* Place seeds on farmland and watch them grow
* Collect plant when fully grown
* If near water, farmland becomes wet and speeds up growth

### Furnace
* Craft furnace
* Furnace allows you to obtain more items
* Upper slot must contain a smeltable item (example: iron ore)
* Lower slot must contain a fuel item (example: coal)
* See tooltips in crafting guide to learn about fuels and smeltable items

### Additional help
More help about the gameplay, blocks items and much more can be found from inside
the game. You can access the help from your inventory menu.

### Special items
The following items are interesting for Creative Mode and for adventure
map builders. They can not be obtained in-game or in the creative inventory.

* Barrier: `mcl_core:barrier`

Use the `/giveme` chat command to obtain them. See the in-game help for
an explanation.

## Installation
This game requires latest stable [Minetest](http://minetest.net) to run, please install
it first. Only latest stable version of Minetest is officially supported.
There are lots of questions about Ubuntu, which has minetest-5.1.1 still.
Please, first of all, visit this page, it should fix the problem: https://launchpad.net/~minetestdevs/+archive/ubuntu/stable
Also, here is endless issue #123: https://git.minetest.land/MineClone5/MineClone5/issues/123 - really less preferable way.

There is no support for running MineClone 5 in development versions of Minetest.

To install MineClone 5 (if you haven't already), move this directory into the
“games” directory of your Minetest data directory. Consult the help of
Minetest to learn more.

## Useful links
The MineClone 5 repository is hosted at Mesehub. To contribute or report issues, head there.

* Mesehub: <https://git.minetest.land/MineClone5/MineClone5>
* Minetest forums: <https://forum.minetest.net/viewtopic.php?f=50&t=27107>
* Semi-official Discord: <https://discord.gg/PUm5YRn7dX>

## Project description
The main goal of **MineClone 5** is to be a clone of Minecraft and to be released as free software.

* **Target of development: Minecraft Java Edition latest version**
* MineClone 5 also includes Optifine features supported by the Minetest engine
* In general, Minecraft is aimed to be cloned as good as possible
* Cloning the gameplay has highest priority
* MineClone 5 will use different assets, but with a similar style
* Limitations found in Minetest will be documented in the course of development
* Features of later Minecraft versions are collected in the mineclone5 branch

## Completion status
This game is currently in **beta** stage.
It is playable, but not yet feature-complete.
Backwards-compability is not entirely guaranteed, updating your world might cause small bugs.

The following main features are available:

* Tools, weapons
* Armor
* Crafting system: 2×2 grid, crafting table (3×3 grid), furnace, including a crafting guide
* Chests, large chests, ender chests, shulker boxes
* Furnaces, hoppers
* Hunger
* Most monsters and animals
* All ores from Minecraft
* Most blocks in the overworld
* Water and lava
* Weather
* 28 biomes
* The Nether, a fiery underworld in another dimension
* Redstone circuits (partially)
* Minecarts (partial)
* Status effects (partial)
* Experience
* Enchanting
* Brewing, potions, tipped arrow (partial)
* Boats
* Fire
* Buidling blocks: Stairs, slabs, doors, trapdoors, fences, fence gates, walls
* Clock
* Compass
* Sponge
* Slime block
* Small plants and saplings
* Dyes
* Banners
* Deco blocks: Glass, stained glass, glass panes, iron bars, hardened clay (and colors), heads and more
* Item frames
* Jukeboxes
* Beds
* Inventory menu
* Creative inventory
* Farming
* Writable books
* Commands
* Villages
* The End
* And more!

The following features are incomplete:

* Some monsters and animals
* Redstone-related things
* Special minecarts
* A couple of non-trivial blocks and items

Bonus features (not found in Minecraft):

* Built-in crafting guide which shows you crafting and smelting recipes
* In-game help system containing extensive help about gameplay basics, blocks, items and more
* Temporary crafting recipes. They only exist to make some otherwise unaccessible items available when you're not in creative mode. These recipes will be removed as development goes on an more features become available
* Saplings in chests in mapgen v6
* Fully moddable (thanks to Minetest's powerful Lua API)
* New blocks and items:
    * Lookup tool, shows you the help for whatever it touches
    * More slabs and stairs
    * Nether Brick Fence Gate
    * Red Nether Brick Fence
    * Red Nether Brick Fence Gate
* Arbitrary-shaped Nether portals

Technical differences from Minecraft:

* Height limit of ca. 31000 blocks (much higher than in Minecraft)
* Horizontal world size is ca. 62000×62000 blocks (much smaller than in Minecraft, but it is still very large)
* Still very incomplete and buggy
* Blocks, items, enemies and other features are missing
* A few items have slightly different names to make them easier to distinguish
* Different music for jukebox
* Different textures (Pixel Perfection)
* Different sounds (various sources)
* Different engine (Minetest)
* Different easter eggs

… and finally, MineClone 5 is free software (“free” as in “freedom”)!

## Other readme files

* `LICENSE.txt`: The GPLv3 license text
* `CONTRIBUTING.md`: Information for those who want to contribute
* `API.md`: For Minetest modders who want to mod this game
* `LEGAL.md`: Legal information
* `CREDITS.md`: List of everyone who contributed

## Menu music

* horizonchris96 — 02_what_we_ll_build_next
