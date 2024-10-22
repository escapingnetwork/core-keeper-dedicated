# Core Keeper Dedicated Server

![corekeeper](https://user-images.githubusercontent.com/136487/168213246-7f561105-136e-47fa-abd9-fac1c97ca48d.png)

Explore an endless cavern of creatures, relics and resources in a mining sandbox adventure for 1-8 players. Mine, build, fight, craft and farm to unravel the mystery of the ancient Core. [Get Core Keeper at the Steam Store](https://store.steampowered.com/app/1621690/Core_Keeper/)

[![Docker Image CI](https://github.com/escapingnetwork/core-keeper-dedicated/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/escapingnetwork/core-keeper-dedicated/actions/workflows/docker-image.yml)

## Supported tags and respective `Dockerfile` links
-	[`latest` (*Dockerfile*)](https://github.com/escapingnetwork/core-keeper-dedicated/blob/main/Dockerfile)

## How to run

### Volumes

Create two directories where you want to run your server :

- `server-data`: mandatory if you want to keep configuration between each restart
- `server-files`: optional, contains all the files of the application

### Using Docker CLI:

`docker run -d -e WORLD_NAME="Core Keeper Server" -e MAX_PLAYERS=5 -v $(pwd)/server-data:/home/steam/core-keeper-data --name core-keeper-dedicated escaping/core-keeper-dedicated`

### Using Docker Compose
Create a `docker-compose.yml` with the following content:

```yml
version: "3"

services:
  core-keeper:
    container_name: core-keeper-dedicated
    image: escaping/core-keeper-dedicated
    volumes:
      - server-files:/home/steam/core-keeper-dedicated
      - server-data:/home/steam/core-keeper-data
    env_file:
      - ./core.env
    restart: always
    stop_grace_period: 2m
volumes:
    server-files:
    server-data:
```

Create a `core.env` file, it should contain the environment variables for the dedicated server, see configuration for reference. Example:
```env
PUID=1000
PGID=1000
WORLD_INDEX=0
WORLD_NAME=Core Keeper Server
WORLD_SEED=0
WORLD_MODE=0
GAME_ID=
DATA_PATH=
MAX_PLAYERS=10
DISCORD_HOOK=https://discord.com/api/webhooks/{id}/{token}
SEASON=-1
SERVER_IP=
SERVER_PORT=
```

On the folder which contains the files run `docker-compose up -d`.

A `GameID.txt` file will be created next to the executable containing the Game ID. If it doesn't appear you can check the log in the same location named `core-keeper-dedicated/CoreKeeperServerLog.txt` for errors.

To query the game ID run:
`docker exec -it core-keeper-dedicated cat core-keeper-dedicated/GameID.txt`

## Configuration

These are the arguments you can use to customize server behavior with default values.

| Argument | Default | Description |
| :---:   | :---: | :---: |
| PUID | 1000 | The user ID on the host that the container should use for file ownership and permissions. |
| PGID | 1000 | The group ID on the host that the container should use for file ownership and permissions. |
| WORLD_INDEX | 0 | Which world index to use. |
| WORLD_NAME | "Core Keeper Server" | The name to use for the server. |
| WORLD_SEED | 0 | The seed to use for a new world. Set to 0 to generate random seed. |
| WORLD_MODE | 0 | Sets the world mode for the world. Can be Normal (0), Hard (1), Creative (2), Casual (4). |
| SEASON | -1 | Overrides current season by setting to any of None (0), Easter (1), Halloween (2), Christmas (3), Valentine (4), Anniversary (5), CherryBlossom (6), LunarNewYear(7) or Normal Date (-1). |
| GAME_ID | "" |  Game ID to use for the server. Need to be at least 28 characters and alphanumeric, excluding Y,y,x,0,O. Empty or not valid means a new ID will be generated at start. |
| MAX_PLAYERS | 10 | Maximum number of players that will be allowed to connect to server. |
| DATA_PATH | "/home/steam/core-keeper-data" | Save file location. |
| DISCORD_HOOK | "" | Webhook url (Edit channel > Integrations > Create Webhook). |
| DISCORD_PRINTF_STR | "%s" | The format string used to generate the content of the Discord webook. |
| SERVER_IP | No Default | Only used if port is set. Sets the address that the server will bind to. |
| SERVER_PORT | No Default | What port to bind to. If not set, then the server will use the Steam relay network. If set the clients will connect to the server directly and the port needs to be open. |
                          
### Contributors
<a href="https://github.com/escapingnetwork/core-keeper-dedicated/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=escapingnetwork/core-keeper-dedicated" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
