# --- Build the current upstream TS3AudioBot develop branch (.NET 10) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS builder

ARG TARGETARCH
ARG BOT_REF=develop

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git wget && \
    rm -rf /var/lib/apt/lists/*

# Install the self-contained yt-dlp binary for the build architecture.
RUN case "$TARGETARCH" in \
      amd64) YTDLP_ASSET="yt-dlp_linux" ;; \
      arm64) YTDLP_ASSET="yt-dlp_linux_aarch64" ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    wget -q --retry-connrefused --waitretry=5 --tries=3 \
      "https://github.com/yt-dlp/yt-dlp/releases/latest/download/${YTDLP_ASSET}" \
      -O /usr/local/bin/yt-dlp && \
    chmod 755 /usr/local/bin/yt-dlp && \
    /usr/local/bin/yt-dlp --version

WORKDIR /src
RUN git clone --depth 1 --branch "${BOT_REF}" --recurse-submodules --shallow-submodules \
      https://github.com/Splamy/TS3AudioBot.git .

RUN dotnet publish TS3AudioBot/TS3AudioBot.csproj \
      --configuration Release \
      --framework net10.0 \
      --output /out \
      --no-self-contained \
      -p:UseAppHost=false


# --- Runtime ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0

LABEL org.opencontainers.image.title="TS3AudioBot"
LABEL org.opencontainers.image.description="TS3AudioBot upstream develop build on .NET 10"
LABEL org.opencontainers.image.source="https://github.com/DoNathaniel/TS3AudioBot-Docker"

ENV DEBIAN_FRONTEND=noninteractive \
    XDG_CACHE_HOME=/tmp/.cache \
    HOME=/tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates ffmpeg curl libopus-dev libicu-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    find / -xdev -perm /6000 -type f -print0 | xargs -0 -r chmod a-s

RUN groupadd -g 9999 ts3audiobot && \
    useradd -ms /usr/sbin/nologin -u 9999 -g 9999 ts3audiobot && \
    mkdir -p /data /opt/TS3AudioBot && \
    chown -R ts3audiobot:ts3audiobot /data

COPY --from=builder --chown=root:root /usr/local/bin/yt-dlp /usr/local/bin/yt-dlp
COPY --from=builder --chown=root:root /out/ /opt/TS3AudioBot/
COPY --chown=root:root ./config/NLog.config /opt/TS3AudioBot/NLog.config

WORKDIR /data
COPY --chown=9999:9999 ./config .
VOLUME /data

USER ts3audiobot
EXPOSE 58913

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -sS http://127.0.0.1:58913/ > /dev/null || exit 1

ENTRYPOINT ["dotnet", "/opt/TS3AudioBot/TS3AudioBot.dll", "--non-interactive", "--stats-disabled"]
