# OC-Von-Neumann-probe
This is a project aiming to create a self-replicating robot, or a [Von Neumann Probe](https://en.wikipedia.org/wiki/Self-replicating_spacecraft) in OpenComputers, a Minecraft mod that adds programmable computers and robots.

## Goals
1. Primary goal is to design and write software for a robot and other auxiliary devices that would make it collect all the required resources and create a perfect copy of itself. That means the goal is met when the robot can successfully place a copy of itself (hardware and software-wise) in the world without or with only minimal initial resource input from the player.
2. Secondary goal is to write software that would make those copies build their own base of operations further away from their home base where they were created and repeat the process of constructing a copy of themselves, now with only the resource and information input from their "parent". That means the goal is met when the robots can successfully create their own bases far enough from their home bases and produce new copies, which then repeat the process, exponentially expanding their operating area.
3. Additional goal is to write software which would make the robots provide player with any surplus resources that they acquire but don't deem necessary for fast progress. 

## Subgoals for primary goal
- [ ] Efficient mining (ore detection using the geolyzer)
- [ ] Seeking specific mob types and killing them (endermans)
- [ ] Rare resource searching (e.g. cactus, sugar cane, emeralds, clay)
- [ ] Keeping track of inventories (robot's own inventory, chests, furnaces, generators etc.)
- [ ] Going to the nether and finding a nether fortress (to farm blaze rods)
- [ ] Tree chopping
- [ ] Farming crops required for making a copy
- [ ] Communication between the robot, potential drones and computer at the home base
