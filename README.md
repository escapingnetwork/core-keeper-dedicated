# Core Keeper Dedicated Server

`APPID 1007`

`TOOLID 1963720`

## How to run

Using Docker CLI:

`docker run -d --name core-keeper-dedicated arguser/core-keeper-dedicated`

Using Docker Compose
Create a `docker-compose.yml` with the following content:

```
version: "3"

services:
  core-keeper:
    image: arguser/core-keeper-dedicated
    env_file:
      - ./core.env
    restart: always
    stop_grace_period: 2m
```

Create a `core.env` file, it should contain the environment variables for the dedicated server, see configuration for reference. Example:
```
WORLD_INDEX=0
WORLD_NAME=Core Keeper Server
WORLD_SEED=0
GAME_ID=
DATA_PATH=
MAX_PLAYERS=10
```

On the folder which contains the files run `docker-compose up -d`.

A `GameID.txt` file will be created next to the executable containing the Game ID. If it doesn't appear you can check the log in the same location named `core-keeper-dedicated/CoreKeeperServerLog.txt` for errors.

To query the game ID run:
`docker exec -it core-keeper-dedicated cat core-keeper-dedicated/GameID.txt`

## Configuration

These are the arguments you can use to customize server behavior with default values.
```
WORLD_INDEX         Which world index to use.
WORLD_NAME          The name to use for the server.
WORLD_SEED          The seed to use for a new world. Set to 0 to generate random seed.
GAME_ID             Game ID to use for the server. Need to be at least 23 characters and alphanumeric, excluding Y,y,x,0,O. Empty or not valid means a new ID will be generated at start.
DATA_PATH           Save file location. If not set it defaults to a sub-folder named "DedicatedServer" at the default Core Keeper save location.
MAX_PLAYERS         Maximum number of players that will be allowed to connect to server.
```