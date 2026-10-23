# TS3AudioBot-Docker

Docker wrapper for [TS3AudioBot](https://github.com/Splamy/TS3AudioBot). The image builds the upstream develop branch, which currently targets .NET 10 and supports current OpenSSL libraries.

> The upstream develop branch is experimental. Use this image for testing until the upstream stable branch moves to a current .NET version.

## Build and run

The Dockerfile clones the upstream repository and compiles TS3AudioBot. Docker needs access to GitHub, NuGet, and the yt-dlp release download during the build.

Run locally:

    docker compose up --build -d
    docker compose logs -f ts3audiobot

For Dokploy, deploy this repository as a Docker Compose service. The Compose file uses build: ., so Dokploy builds the local Dockerfile instead of pulling a prebuilt image.

## Configuration and persistence

The named volume ts3audiobot-data is mounted at /data. Bot configuration, identity, logs, and database files are stored there and survive container redeploys.

The web API listens on port 58913. The Compose file only exposes it to containers on Dokploy's dokploy-network; it does not publish the API to the public host.

On first startup, TS3AudioBot creates its configuration and identity. Add the bot identity to the TeamSpeak server's identity whitelist if the server requires it.

Full configuration and command references are in the [TS3AudioBot Wiki](https://github.com/Splamy/TS3AudioBot/wiki).

## Build options

By default, the Dockerfile builds the upstream develop branch:

    docker build --build-arg BOT_REF=develop -t ts3audiobot-docker:develop .

You can set BOT_REF to another upstream branch or commit that targets .NET 10.

The image runs as an unprivileged user, uses a read-only root filesystem, drops Linux capabilities, and enables no-new-privileges.

## License

This Docker wrapper is MIT licensed. TS3AudioBot itself is licensed under OSL-3.0.
