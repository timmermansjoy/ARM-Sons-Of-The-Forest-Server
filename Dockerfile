FROM debian:bookworm-slim as build

ENV DEBIAN_FRONTEND="noninteractive"

# Install libraries needed to compile box
RUN dpkg --add-architecture armhf \
 && apt-get update \
 && apt-get install -y --no-install-recommends --no-install-suggests git wget curl cmake python3 build-essential gcc-arm-linux-gnueabihf libc6-dev-armhf-cross libc6:armhf libstdc++6:armhf ca-certificates unzip

WORKDIR /root

# Build box86
RUN git clone https://github.com/ptitSeb/box86 \
 && mkdir box86/build \
 && cd box86/build \
 && cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo \
 && make -j$(nproc) \
 && make install DESTDIR=/box

# Build box64
RUN git clone https://github.com/ptitSeb/box64 \
 && mkdir box64/build \
 && cd box64/build \
 && cmake .. -DRPI4ARM64=1 -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo \
 && make -j$(nproc) \
 && make install DESTDIR=/box

FROM debian:bookworm-slim

# Copy compiled box86 and box64 binaries
COPY --from=build /box /

# Install libraries needed to run box
RUN dpkg --add-architecture armhf \
 && apt-get update \
 && apt-get install --yes --no-install-recommends wget curl libc6:armhf libstdc++6:armhf ca-certificates unzip

# `cabextract` is needed by winetricks to install most libraries
# `xvfb` is needed in wine to spawn display window because some Windows program can't run without it (using `xvfb-run`)
# If you are sure you don't need it, feel free to remove
RUN apt install -y cabextract xvfb

# Clean up
RUN apt-get -y autoremove \
 && apt-get clean autoclean \
 && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists

# Install wine, wine64, and winetricks
COPY scripts/install-wine.sh /
RUN bash /install-wine.sh \
 && rm /install-wine.sh

# Install box wrapper for wine
COPY scripts/wrap-wine.sh /
RUN bash /wrap-wine.sh \
 && rm /wrap-wine.sh

# Download and set up SteamCMD
RUN mkdir /steamcmd && cd /steamcmd \
 && wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip \
 && unzip steamcmd.zip

# Create directory for Sons of the Forest and set permissions
RUN mkdir /sonsoftheforest && chmod 777 /sonsoftheforest

EXPOSE 8766/udp 27016/udp 9700/udp

# #install the forst
COPY scripts/install-forest.sh /
RUN bash /install-forest.sh
RUN ls

WORKDIR /sonsoftheforest

# Copy the start-server script and make sure it's executable
COPY scripts/start-server.sh /sonsoftheforest/start-server.sh
RUN chmod +x /sonsoftheforest/start-server.sh

# Use the script as the entry point
ENTRYPOINT ["bash", "start-server.sh"]
