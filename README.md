# Core Keeper Dedicated Server

![corekeeper](https://user-images.githubusercontent.com/136487/168213246-7f561105-136e-47fa-abd9-fac1c97ca48d.png)

Explore an endless cavern of creatures, relics and resources in a mining sandbox adventure for 1-8 players. Mine, build, fight, craft and farm to unravel the mystery of the ancient Core. [Get Core Keeper at the Steam Store](https://store.steampowered.com/app/1621690/Core_Keeper/)

[![Docker Image CI](https://github.com/escapingnetwork/core-keeper-dedicated/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/escapingnetwork/core-keeper-dedicated/actions/workflows/docker-image.yml)

## Supported tags and respective `Dockerfile` links
-	[`latest` (*Dockerfile*)](https://github.com/escapingnetwork/core-keeper-dedicated/blob/main/Dockerfile)

## How to run

### ARM based configuration

This image currently includes the following Box64 build variants for the following devices:

- Generic [generic]
- Raspberry Pi 3 [rpi3]
- Raspberry Pi 4 [rpi4-pre3]
- Raspberry Pi 5 (4K page size) [rpi5]
- Raspberry Pi 5 (16K page size) [rpi5_16k]
- M1 (M-Series) Mac [m1]
- ADLink Ampere Altra (Oracle ARM CPUs) [adlink]

By default it is set to use `generic`. If you want to use another one, change the enviromental variable `ARM64_DEVICE` at the `core.env` file.

### Volumes

Create two directories where you want to run your server :

- `server-data`: mandatory if you want to keep configuration between each restart
- `server-files`: optional, contains all the files of the application

### Using Docker CLI:

`docker run -d -e WORLD_NAME="Core Keeper Server" -e MAX_PLAYERS=5 -p 27015:27015/udp -v $(pwd)/server-data:/home/steam/core-keeper-data --name core-keeper-dedicated escaping/core-keeper-dedicated`

### Using Docker Compose
Create a `docker-compose.yml` with the following content:

```yml
services:
  core-keeper:
    container_name: core-keeper-dedicated
    image: escaping/core-keeper-dedicated
    ports:
      - "$SERVER_PORT:$SERVER_PORT/udp"
    volumes:
      - server-files:/home/steam/core-keeper-dedicated
      - server-data:/home/steam/core-keeper-data
    restart: unless-stopped
    env_file:
      - path: override.env
        required: false
    stop_grace_period: 2m
volumes:
    server-files:
    server-data:
```

Create a `override.env` file and override the desired environmental variables for the dedicated server, see configuration for reference. Example:
```env
ARM64_DEVICE=rpi5
MAX_PLAYERS=3
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
| ARM64_DEVICE | generic | The Box64 build variants. Accepts `generic`, `rpi5`, `m1` and `adlink`. |
| USE_DEPOT_DOWNLOADER | false | Use Depot downloader instead of steamcmd. Useful for system not compatible with 32 bits. |
| WORLD_INDEX | 0 | Which world index to use. |
| WORLD_NAME | "Core Keeper Server" | The name to use for the server. |
| WORLD_SEED | "" | The seed to use for a new world. Set to "" to generate random seed. |
| WORLD_MODE | 0 | Sets the world mode for the world. Can be Normal (0), Hard (1), Creative (2), Casual (4). |
| SEASON | No Default | Overrides current season by setting to any of None (0), Easter (1), Halloween (2), Christmas (3), Valentine (4), Anniversary (5), CherryBlossom (6), LunarNewYear(7).<br/>**Do not set this env var if you want real date season.** |
| GAME_ID | "" |  Game ID to use for the server. Need to be at least 28 characters and alphanumeric, excluding Y,y,x,0,O. Empty or not valid means a new ID will be generated at start. |
| DATA_PATH | "/home/steam/core-keeper-data" | Save file location. |
| MAX_PLAYERS | 10 | Maximum number of players that will be allowed to connect to server. |
| SERVER_IP | No Default | Only used if port is set. Sets the address that the server will bind to. |
| SERVER_PORT | 27015 | What port to bind to. 27015 is the Steam relay port. |
| DISCORD_WEBHOOK_URL | "" | Webhook url (Edit channel > Integrations > Create Webhook). |
| DISCORD_PLAYER_JOIN_ENABLED | true | Enable/Disable message on player join |
| DISCORD_PLAYER_JOIN_MESSAGE | `"$${char_name} ($${steamid}) has joined the server."` | Embed message |
| DISCORD_PLAYER_JOIN_TITLE | "Player Joined" | Embed title |
| DISCORD_PLAYER_JOIN_COLOR | "47456" | Embed color |
| DISCORD_PLAYER_LEAVE_ENABLED | true | Enable/Disable message on player leave |
| DISCORD_PLAYER_LEAVE_MESSAGE | `"$${char_name} ($${steamid}) has disconnected. Reason: $${reason}."` | Embed message |
| DISCORD_PLAYER_LEAVE_TITLE | "Player Left" | Embed title |
| DISCORD_PLAYER_LEAVE_COLOR | "11477760" | Embed color |
| DISCORD_SERVER_START_ENABLED | true | Enable/Disable message on server start |
| DISCORD_SERVER_START_MESSAGE | `"**World:** $${world_name}\n**GameID:** $${gameid}"` | Embed message |
| DISCORD_SERVER_START_TITLE | "Server Started" | Embed title |
| DISCORD_SERVER_START_COLOR | "2013440" | Embed color |
| DISCORD_SERVER_STOP_ENABLED | true | Enable/Disable message on server stop |
| DISCORD_SERVER_STOP_MESSAGE | "" | Embed message |
| DISCORD_SERVER_STOP_TITLE | "Server Stopped" | Embed title |
| DISCORD_SERVER_STOP_COLOR | "12779520" | Embed color |
| MODS_ENABLED | false | Enable/Disable mod support |
| MODIO_API_KEY | "" | mod.io API key |
| MODIO_API_URL | "" | mod.io API path |
| MODS | "" | List of mods to install |

## Mod Support

The container supports automatically installing mods from [mod.io](https://mod.io/g/corekeeper).

1. Get a mod.io API key from [mod.io/me/access](https://mod.io/me/access)
    - You'll need the API path that is generated along with the key (e.g. https://u-*.modapi.io/v1)
2. Set the necessary environment variables in your `override.env` file (or in your `docker-compose.yml`)
  - `MODS_ENABLED=true`
  - `MODIO_API_KEY=your_api_key`
  - `MODIO_API_URL=your_api_url`
  - `MODS=mod1,mod2` (see below)

### Specify mods to install

> [!WARNING]
> Installing a client-only mod can cause the server to not start. Don't install client-only mods (they wouldn't do anything on the server anyway).

> [!IMPORTANT]
> Mod dependencies are not automatically installed. You must look at the dependencies for each mod you want to install and add their dependencies to the list.

You'll need to get the mod string ID from mod.io for each mod you want to install. The easiest way to do this is to grab it from the URL.

For example, looking at the URL for [CoreLib](https://mod.io/g/corekeeper/m/core-lib) (`https://mod.io/g/corekeeper/m/core-lib`), you would use `core-lib`.

Specify mods as a comma-separated list, optionally providing a version:

```sh
# Format: <mod_id>[:<version>], ...
MODS=core-lib,coreliblocalization,corelibrewiredextension,ck-qol
```

Example using specific versions:

```sh
MODS=core-lib,coreliblocalization,corelibrewiredextension:3.0.1,ck-qol:1.9.4
```

- If `version` is not specified, the latest version will be installed.
- Mods are reinstalled whenever the container is started, so to update mods to their latest version, simply restart the container.

### Contributors
<a href="https://github.com/escapingnetwork/core-keeper-dedicated/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=escapingnetwork/core-keeper-dedicated" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
