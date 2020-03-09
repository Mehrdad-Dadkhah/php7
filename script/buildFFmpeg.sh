#!/usr/bin/env bash
set -eo pipefail
set -x

apt-get update
apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev \
  libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texinfo wget zlib1g-dev libnuma-dev

mkdir -p ~/ffmpeg_sources
MAKEFLAGS=${MAKEFLAGS:-"-j5"}

apt-get -y install yasm || (cd ~/ffmpeg_sources \
    && wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz \
    && tar xzvf yasm-1.3.0.tar.gz \
    && cd yasm-1.3.0 \
    && ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" \
    && make && make install)

cd ~/ffmpeg_sources
wget http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
tar xjvf nasm-2.14.02.tar.bz2
cd nasm-2.14.02
./autogen.sh
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
PATH="$HOME/bin:$PATH" make
make install

apt-get -y install libx264-dev || (cd ~/ffmpeg_sources \
    && wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2 \
    && tar xjvf last_x264.tar.bz2 \
    && cd x264-snapshot* \
    && PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-opencl \
    && PATH="$HOME/bin:$PATH" make ${MAKEFLAGS} \
    && make install)

apt-get -y install libx265-dev || (apt-get -y install cmake mercurial \
    && cd ~/ffmpeg_sources \
    && rm -rf x265 \
    && hg clone https://bitbucket.org/multicoreware/x265 \
    && cd ~/ffmpeg_sources/x265/build/linux \
    && PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source \
    && make ${MAKEFLAGS} \
    && make install)

apt-get -y install libfdk-aac-dev || (cd ~/ffmpeg_sources \
    && wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master \
    && tar xzvf fdk-aac.tar.gz \
    && cd mstorsjo-fdk-aac* \
    && autoreconf -fiv \
    && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared \
    && make ${MAKEFLAGS} \
    && make install)

apt-get -y install libmp3lame-dev || (cd ~/ffmpeg_sources \
    && wget http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz \
    && tar xzvf lame-3.100.tar.gz \
    && cd lame-3.100 \
    && ./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --disable-shared \
    && make ${MAKEFLAGS} \
    && make install)

apt-get -y install libopus-dev || (cd ~/ffmpeg_sources \
    && wget https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz \
    && tar xzvf opus-1.3.1.tar.gz \
    && cd opus-1.3.1 \
    && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared \
    && make ${MAKEFLAGS} \
    && make install)

apt-get -y install libvpx-dev || (apt-get -y install git \
    && cd ~/ffmpeg_sources \
    && rm -rf libvpx \
    && git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git \
    && cd libvpx \
    && PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests \
    && PATH="$HOME/bin:$PATH" make ${MAKEFLAGS} \
    && make install)

cd ~/ffmpeg_sources
wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
PATH="$HOME/bin:$PATH" make ${MAKEFLAGS}
make install
hash -r

apt-get -y install ffmpegthumbnailer

cp ~/bin/* /usr/bin/
