# OpenComputers self-replicating robot
This is a project aiming to create a self-replicating robot, or a [Von Neumann Probe](https://en.wikipedia.org/wiki/Self-replicating_spacecraft) in OpenComputers, a Minecraft mod that adds programmable computers and robots.

## Goals
1. Primary goal is to design and write software for a robot and other auxiliary devices that would make it collect all the required resources and create a perfect copy of itself. That means the goal is met when the robot can successfully place a copy of itself (hardware and software-wise) in the world without or with only minimal initial resource input from the player.
2. Secondary goal is to write software that would make those copies build their own base of operations further away from their home base where they were created and repeat the process of constructing a copy of themselves, now with only the resource and information input from their "parent". That means the goal is met when the robots can successfully create their own bases far enough from their home bases and produce new copies, which then repeat the process, exponentially expanding their operating area.
3. Additional goal is to write software which would make the robots provide player with any surplus resources that they acquire but don't deem necessary for fast progress. 

## Subgoals for primary goal
- [ ] General
  - [x] Pathfinding with A*
  - [ ] Efficient pathfinding with Jump Point Search on unweighted grid, with chunk scanning before moving into them
  - [ ] Keeping track of experience which affects robot's movement, turn and block breaking speed stats for calculating pathfinding cost and heuristic
  - [ ] Keeping track of tool damage and recrafting it if broken
  - [ ] Recognizing specific structures from map data
  - [ ] Keeping track of robot's energy level, fuel left and going to the lcharging location if energy is low enough and fuel spent
  - [ ] Customizable logging with different levels and targets (stdout, file, network)
  - [ ] Visualisation library for easier debugging with OpenGlasses2
- [ ] Efficient mining
  - [x] Scanning ore locations with the geolyzer
  - [x] Planning efficient path with TSP algorithms
  - [x] Going between and mining ore lumps
  - [ ] Unloading mined resources at the base
  - [ ] Pathfinding to a new, unvisited chunk, scanning it before moving into it
- [ ] Seeking specific mob types and killing them
  - [ ] Following entities based on motion detector events
  - [ ] Killing the entity
  - [ ] Patrolling an area during nighttime to hunt for endermans
- [ ] Rare resource and biome searching
  - [ ] Determine what the search area should be for each type of resource
  - [ ] Calculating and preparing amount of fuel required for a long journey
  - [ ] Algorithms for searching a biome and acquiring each resource (some of them can be detected using structure recognizer algorithm)
    - [ ] Desert/cactus
    - [ ] River/sugar cane
    - [ ] River/clay
    - [ ] River/gravel (flint)
    - [ ] Mountains/emerald
- [ ] Keeping track of inventories and crafting
  - [x] Tracking robot's inventory changes by hooking to component methods
  - [ ] Tracking base's chests' inventories, with their location
  - [ ] Tracking base's furnaces' inventories and estimating their smelting progress and fuel left as time passes
  - [ ] Tracking base's energy generators' inventories and estimating their fuel left as time passes
  - [ ] Storage and retrieval of crafting recipes with some data structure
  - [ ] Crafting through standardized API without crafting area preparations (only making sure the robot has enough ingredients for crafting the desired recipe and amount of items
- [ ] Going to the nether and finding a nether fortress (to farm blaze rods)
  - [ ] Acquiring obsidian and flint and steel
  - [ ] Building and lighting up the portal
  - [ ] Crafting a drone and a helper robot
  - [ ] Calculating the required amount of fuel for a long journey
  - [ ] Writing software for the helper robot which would break the main robot, and the drone which would pick it up and transport it through the portal and place it on the other side (need to wait for issue https://github.com/MightyPirates/OpenComputers/issues/3210 to be fixed)
  - [ ] Finding the nether fortress structure and blaze spawner inside it
  - [ ] Farming the required number of blaze rods
  - [ ] Going back to the overworld with a drone
- [ ] Tree chopping
  - [ ] Recognizing trees from map data with structure recognizer algorithm
  - [ ] Chopping trees efficiently, similar to how ore mining works
- [ ] Farming crops required for making a copy
  - [ ] Acquiring seeds for the required crops
  - [ ] Choosing appropriate area for a farm field
  - [ ] Making an efficient farming pattern and planting the seeds
  - [ ] Estimating how much time will it take for the crops to grow
  - [ ] Checking when the it's near the estimated time, the robot is near and on the surface
- [ ] Communication between the robot, potential drones and computer at the home base
  - [ ] Describe a protocol for efficient (energy-wise) communication between the devices
  - [ ] Implement the protocol using functions only available on the EEPROM to make sharing code between the devices easier
  - [ ] Write software for the computer which would receive signals from the robot to install new robot's software on the hard drive and start the assembler

## Technical details about random aspects
### Robot design\*
![Robot design](https://github.com/Kristopher38/OC-Von-Neumann-probe/blob/master/docs/robot.png?raw=true)

\*Hover upgrade tier 2 goes into the upgrade container
