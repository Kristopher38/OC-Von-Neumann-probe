# OpenComputers self-replicating robot
This is a project aiming to create a self-replicating robot, or a [Von Neumann Probe](https://en.wikipedia.org/wiki/Self-replicating_spacecraft) in OpenComputers, a Minecraft mod that adds programmable computers and robots.

## Goals
1. Primary goal is to design and write software for a robot and other auxiliary devices that would make it collect all the required resources and create a perfect copy of itself. That means the goal is met when the robot can successfully place a copy of itself (hardware and software-wise) in the world without or with only minimal initial resource input from the player.
2. Secondary goal is to write software that would make those copies build their own base of operations further away from their home base where they were created and repeat the process of constructing a copy of themselves, now with only the resource and information input from their "parent". That means the goal is met when the robots can successfully create their own bases far enough from their home bases and produce new copies, which then repeat the process, exponentially expanding their operating area.
3. Additional goal is to write software which would make the robots provide player with any surplus resources that they acquire but don't deem necessary for fast progress. Also implementing long range communication between the robots and bases would be cool as it would allow plotting nice graphs about resources mined, progress, expansion and so on. That requires ender pearls to be acquired by trading with villagers, and only on minecraft version 1.12.

## Subgoals for primary goal
- [ ] General
  - [x] Pathfinding with A*
  - [ ] Safe movement: make sure robot can always reach the desired destination, even if there are obstacles (falling gravel/sand, entities) along the way or the destination is in the air (algorithm for movement without any hover upgrade)
  - [ ] Efficient pathfinding with Jump Point Search on unweighted grid, with chunk scanning before moving into them
  - [ ] Keeping track of experience which affects robot's movement, turn and block breaking speed stats for calculating pathfinding cost and heuristic
  - [ ] Keeping track of tool damage and recrafting it if broken
  - [ ] Recognizing specific structures from map data
  - [ ] Keeping track of robot's energy level, fuel left and going to the charging location if energy is low enough and fuel spent
  - [x] Customizable logging with different levels and targets (stdout, file, network)
  - [x] Visualisation library for easier debugging with OpenGlasses2
- [ ] Efficient mining
  - [x] Scanning ore locations with the geolyzer
  - [x] Planning efficient path with TSP algorithms
  - [x] Going between and mining ore lumps
  - [ ] Unloading mined resources at the base
  - [ ] Pathfinding to a new, unvisited chunk, scanning it before moving into it
- [ ] Rare resource and biome searching
  - [ ] Determine what the search area should be for each type of resource
  - [ ] Calculating and preparing amount of fuel required for a long journey
  - [ ] Algorithms for searching a biome and acquiring each resource (some of them can be detected using structure recognizer algorithm)
    - [ ] Desert/cactus
    - [ ] River/sugar cane
    - [ ] River/clay
    - [ ] Mountains/emerald
- [ ] Keeping track of inventories and crafting
  - [x] Tracking robot's inventory changes by hooking to component methods
  - [x] Tracking base's chests' inventories, with their location
  - [ ] Tracking base's furnaces' inventories and estimating their smelting progress and fuel left as time passes
  - [ ] Tracking base's energy generators' inventories and estimating their fuel left as time passes
  - [ ] Storage and retrieval of crafting recipes with some data structure
  - [ ] Crafting through standardized API without crafting area preparations (only making sure the robot has enough ingredients for crafting the desired recipe and amount of items
- [ ] Tree chopping
  - [ ] Recognizing trees from map data with structure recognizer algorithm
  - [ ] Chopping trees efficiently, similar to how ore mining works
- [ ] Farming crops required for making a copy
  - [ ] Acquiring cacti and sugar canes
  - [ ] Choosing appropriate area for a farm field
  - [ ] Making an efficient farming pattern and planting crops
  - [ ] Estimating how much time will it take for the crops to grow
  - [ ] Checking crop growth periodically when the robot is near and on the surface
- [ ] Communication between the robot and computer at the home base
  - [ ] Come up with a protocol for efficient (energy-wise) communication between the devices
  - [ ] Write software for the computer which would receive signals from the robot to install new robot's software on the hard drive, the eeprom and start the assembler

## Rough algorithm
### Primary goal
1. Searching for a biome with trees and harvesting resources
    - at least 41 logs
    - a few saplings for a tree farm
    - a few extra logs to make new tools
2. Mining enough resources
    - coal
    - redstone
    - gold
    - iron
    - diamonds
    - cobblestone
3. Smelting ores to ingots and crafting 2 buckets
4. Finding lava (in existing visited chunk's data) and getting 2 lava buckets
5. Searching for a river and harvesting resources from it
    - clay
    - sugar cane
    - sand
    - obsidian (made with buckets of lava)
    - 2 buckets of water
6. Setting up sugarcane farm
    - making infinite water supply
    - making checkerboard pattern
    - planting sugarcane, in the final stage at least 31 blocks
7. Searching for specific biomes and harvesting resources
    - desert: min. 2 cacti
    - mountains: 3 emeralds
8. Robot assembly
    - crafting parts
    - writing software to disk
    - putting parts in the assembler and starting the assembly
    - placing the robot, turning it on, configuring it, providing it with starting renewable resources (water, cacti, sugar canes, mining equipment) and data about locations of various biomes and villages
### Secondary goal
- Making a tree farm
- Making a cactus farm
- Moving bases when resources in the near area are spent
### Tertiary goal
- Communicating with other robots about map data and other stuff
- Communicating with the main base about map data and for statistics acquisition

### Interruptions
Interruptions are events that happen (usually asynchronously or during execution of code which shouldn't handle them explicitly for clarity reasons) during execution of specific task, e.g. mining, which either have to be dealt with immmediately or can be scheduled to be done later. Those include:
- going below some energy threshold - immediate response
- going low on generator fuel - immediate response
- fully filling up robot's internal inventory - immediate response
- furnace smelting job has finished - postponed response
- crops have grown/need check if grown - postponed response

## Technical details about random aspects
### Robot design\*
![Robot design](https://github.com/Kristopher38/OC-Von-Neumann-probe/blob/master/docs/robot.png?raw=true)

\*Additional inventory upgrades go into the upgrade containers, design subject to change

\*Wireless network card is tier 1 because it doesn't require ender pearls to craft and those are impossible to get without player presence

### Summarized material list
Quantity | Material | Method of acquisition
-------- | -------- | ---------------------
198 | Iron Ingot | Mining
138 | Redstone | Mining
82 | Cobblestone | Mining
39 | Gold Ingot | Mining
32 | Coal | Mining (for smelting ores and other items)
23 | Diamond | Mining
3 | Emerald | Mining
45 | Sugar Canes | Harvesting from the river (need to find a river)
41 | Oak Wood | Harvesting from the sorrounding area (need to find a biome with trees)
2 | Cactus | Harvesting in the desert (need to find a desert)
2 | Clay (block) | Harvesting from the river (need to find a river)
2 | Obsidian | Artificially making it with water and lava
1 | Sand | Harvesting from the river or the desert (need to find a river/desert)
