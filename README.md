# A simple game server
This is a simple game server implemented with skynet. It is still under development and not ready for real deployment. In addition, this project focuses on server side of game, so there is only a test client without any real graphics.

## Overview:
- MongoDB for data persistence
- Redis for buffering data that is not very frequently accessed and less likely to be changed than accessed (e.g. login, friend)
- Other data (e.g. bag, detail attributes) is kept in memory
- 5 kinds of nodes (connection, global functions, world, zone, database)
- fixed sight AOI and simple state synchronization

## Current Status:
- Simple login verification without encryption
- Battle with basic attack
- Level system with attribute points
- Equipments with different grades and detail attributes
- Monsters with simple AI that will chase and attack player near them
