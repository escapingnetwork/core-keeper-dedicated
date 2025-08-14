# Core Keeper Dedicated Server

![corekeeper](https://user-images.githubusercontent.com/136487/168213246-7f561105-136e-47fa-abd9-fac1c97ca48d.png)

Explore an endless cavern of creatures, relics and resources in a mining sandbox adventure for 1-8 players. Mine, build, fight, craft and farm to unravel the mystery of the ancient Core. [Get Core Keeper at the Steam Store](https://store.steampowered.com/app/1621690/Core_Keeper/)

[![Docker Image CI](https://github.com/escapingnetwork/core-keeper-dedicated/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/escapingnetwork/core-keeper-dedicated/actions/workflows/docker-image.yml)

## Supported tags and respective `Dockerfile` links
-	[`latest` (*Dockerfile*)](./Dockerfile)

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

Then modify `/host/path/to/server-data` and/or `/host/path/to/server-files` in one of the examples below to match the paths of the folders you created.

### Using Docker CLI:

```bash
docker run -d \
  --name core-keeper-dedicated \
  -e WORLD_NAME="Core Keeper Server" \
  -e MAX_PLAYERS=5 \
  -v /host/path/to/server-data:/home/steam/core-keeper-data \
  -v /host/path/to/server-files:/home/steam/core-keeper-dedicated \
  escaping/core-keeper-dedicated:latest
```

### Using Docker Compose
Create a [`docker-compose.yml`](./docker-compose-example/docker-compose.yml) with the following content:

```yml
services:
  core-keeper:
    image: escaping/core-keeper-dedicated:latest
    container_name: core-keeper-dedicated
    restart: unless-stopped
    stop_grace_period: 2m
    # Port is only needed if using direct connection mode
    # ports:
    #   - "$SERVER_PORT:$SERVER_PORT/udp"
    volumes:
      - /host/path/to/server-files:/home/steam/core-keeper-dedicated
      - /host/path/to/server-data:/home/steam/core-keeper-data
    env_file:
      - path: core.env
        required: false
```

Create a `core.env` file and override the desired environmental variables for the dedicated server, see configuration for reference. Example:
```env
ARM64_DEVICE=rpi5
MAX_PLAYERS=3
```

On the folder which contains the files run `docker compose up -d`.

A `GameID.txt` file will be created next to the executable containing the Game ID. If it doesn't appear you can check the docker logs (`docker logs core-keeper-dedicated` or `docker compose logs`) for errors.

To query the game ID run:
`docker exec -it core-keeper-dedicated cat /home/steam/core-keeper-dedicated/GameID.txt`

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
| HASHED_WORLD_SEED | "" | The hashed seed to use for a new world, added in v1.1. Set to "" to generate random seed. |
| WORLD_MODE | 0 | Sets the world mode for the world. Can be Normal (0), Hard (1), Creative (2), Casual (4). |
| SEASON | No Default | Overrides current season by setting to any of None (0), Easter (1), Halloween (2), Christmas (3), Valentine (4), Anniversary (5), CherryBlossom (6), LunarNewYear(7).<br/>**Do not set this env var if you want real date season.** |
| GAME_ID | "" |  Game ID to use for the server. Need to be at least 28 characters and alphanumeric, excluding Y,y,x,0,O. Empty or not valid means a new ID will be generated at start. |
| MAX_PLAYERS | 10 | Maximum number of players that will be allowed to connect to server. |
| SERVER_IP | No Default | Only used if port is set. Sets the address that the server will bind to. |
| SERVER_PORT | No Default | Port used for direct connection mode. **Setting an value to this will cause the server behaviour to change!** [See Network Mode](#network-mode) |
| PASSWORD | No Default | Password players should use when trying to join using direct connections. Maximum length password can be 28 characters. If omitted or invalid, a random password will be generated.|
| ALLOW_ONLY_PLATFORM | No Default | Allow players from given platform. Has no effect unless -port is also set enabling Direct Connections. Can be Steam (1), Epic (2), Microsoft (3), GOG (4).  |
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
| ACTIVATE_CONTENT | "" | Comma separated list to turn on biomes for worlds created prior to v1.1. Valid values are `GiantCicadaBossDungeon`, `NatureBiomeCicadas`, `GuaranteedOases`, and `AbioticFactor`. Once enabled, they cannot be disabled! |

## Mod Support

The container supports automatically installing mods from [mod.io](https://mod.io/g/corekeeper).

1. Get a mod.io API key from [mod.io/me/access](https://mod.io/me/access)
    - You'll need the API path that is generated along with the key (e.g. https://u-*.modapi.io/v1)
2. Set the necessary environment variables in your `core.env` file (or in your `docker-compose.yml`)
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

## Network Mode

Currently Core Keeper supports two network modes: SDR (Steam Datagram Relay) and Direct Connect.

### SDR (Steam Datagram Relay)
In this mode, the server uses [Valve's Virtual Network](https://partner.steamgames.com/doc/features/multiplayer/steamdatagramrelay) to route traffic through Steam's relay infrastructure. Instead of players connecting directly to the server's IP address, all communication goes through secure relay nodes managed by Steam. This hides the server’s real IP, protects against DDoS attacks, and improves NAT traversal.

Because of this relay system, server operators do not need to open any ports on their router or firewall—as long as outbound connections to Steam are allowed, the server can communicate with clients reliably.

### Direct Connection
In Direct Connect mode, players connect straight to the server’s public IP address without going through Steam's relay network. This can result in lower latency and more direct communication, but it requires the server to be reachable from the internet.

Server operators must open and forward the necessary ports on their router or firewall to allow incoming connections. Unlike SDR, this mode exposes the server’s IP address to clients and may be more vulnerable to connection issues or attacks.

> [!IMPORTANT]<br>
> The SERVER_PORT environment variable determines the server's network mode.<br>
> Leave it empty to use SDR (no port forwarding needed).<br>
> Setting a value switches to Direct Connect, which requires opening and forwarding ports.<br>
> Only set this if you specifically want Direct Connect.

### Contributors
<a href="https://github.com/escapingnetwork/core-keeper-dedicated/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=escapingnetwork/core-keeper-dedicated" />
</a>

Made with [contrib.rocks](https://contrib.rocks).
