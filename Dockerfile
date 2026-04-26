FROM ubuntu:22.04

RUN apt update && apt install -y \
 build-essential clang flex bison g++ gawk gcc-multilib \
 gettext git libncurses-dev libssl-dev python3 python3-distutils unzip zlib1g-dev \
 file wget rsync ca-certificates pkg-config autoconf automake libtool libnss3-tools zstd

WORKDIR /opt

RUN wget https://downloads.openwrt.org/releases/25.12.2/targets/ramips/mt7620/openwrt-sdk-25.12.2-ramips-mt7620_gcc-14.3.0_musl.Linux-x86_64.tar.zst \
 && tar -xf openwrt-sdk-*.tar.zst \
 && rm openwrt-sdk-*.tar.zst \
 && mv openwrt-sdk-* sdk

WORKDIR /opt/sdk

COPY build.sh /build/build.sh
CMD ["/bin/bash", "/build/build.sh"]
