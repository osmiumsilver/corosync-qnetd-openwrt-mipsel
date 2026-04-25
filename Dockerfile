FROM ubuntu:22.04


RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list \
 && sed -i 's|http://security.ubuntu.com|http://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list

RUN apt update && apt install -y \
 build-essential clang flex bison g++ gawk gcc-multilib \
 gettext git libncurses-dev libssl-dev python3 python3-distutils unzip zlib1g-dev \
 file wget rsync ca-certificates pkg-config autoconf automake libtool libnss3-tools zstd

WORKDIR /opt

# RUN wget https://mirrors.ustc.edu.cn/immortalwrt/releases/24.10.4/targets/ramips/mt7620/immortalwrt-sdk-24.10.4-ramips-mt7620_gcc-13.3.0_musl.Linux-x86_64.tar.zst \
COPY immortalwrt-sdk-24.10.4-ramips-mt7620_gcc-13.3.0_musl.Linux-x86_64.tar.zst .
RUN tar -xf immortalwrt-sdk-*.tar.zst \
 && rm immortalwrt-sdk-*.tar.zst \
 && mv immortalwrt-sdk-* sdk

WORKDIR /opt/sdk

COPY build.sh /build/build.sh
CMD ["/bin/bash", "/build/build.sh"]
