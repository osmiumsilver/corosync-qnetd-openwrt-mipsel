FROM ubuntu:22.04

RUN apt update && apt install -y \
 build-essential clang flex bison g++ gawk gcc-multilib \
 gettext git libncurses-dev libssl-dev python3 python3-distutils unzip zlib1g-dev \
 file wget rsync ca-certificates pkg-config autoconf automake libtool libnss3-tools

WORKDIR /opt

RUN wget https://downloads.openwrt.org/releases/23.05.3/targets/armsr/armv8/openwrt-sdk-23.05.3-armsr-armv8_gcc-12.3.0_musl.Linux-x86_64.tar.xz \
 && tar -xf openwrt-sdk-*.tar.xz \
 && rm openwrt-sdk-*.tar.xz \
 && mv openwrt-sdk-* sdk

WORKDIR /opt/sdk

COPY build.sh /build/build.sh
CMD ["/bin/bash", "/build/build.sh"]
