###############################
# Build the FFmpeg-build image.
FROM alpine:3.13 as build

ARG FFMPEG_VERSION=4.4

ARG PREFIX=/opt/ffmpeg
ARG LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG MAKEFLAGS="-j4"

# FFmpeg build dependencies.
RUN apk add --update \
  build-base \
  coreutils \
  freetype-dev \
  gcc \
  lame-dev \
  libogg-dev \
  libass \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  libsrt \
  libsrt-dev \
  opus-dev \
  openssl \
  openssl-dev \
  pkgconf \
  pkgconfig \
  rtmpdump-dev \
  wget \
  x264-dev \
  x265-dev \
  yasm

# Get fdk-aac from community.
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
  apk add --update fdk-aac-dev

# Get rav1e from testing.
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk add --update rav1e-dev

# Get ffmpeg source.
RUN cd /tmp/ && \
  wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-librav1e \
  --enable-libsrt \
  --enable-postproc \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-cflags="-I${PREFIX}/include" \
  --extra-ldflags="-L${PREFIX}/lib" \
  --extra-libs="-lpthread -lm" \
  --prefix="${PREFIX}" && \
  make && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/apk/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.13
LABEL MAINTAINER Alfred Gutierrez <alf.g.jr@gmail.com>
ENV PATH=/opt/ffmpeg/bin:$PATH

RUN apk add --update \
  ca-certificates \
  openssl \
  pcre \
  lame \
  libogg \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  libsrt \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build /opt/ffmpeg /opt/ffmpeg
COPY --from=build /usr/lib/libfdk-aac.so.2 /usr/lib/libfdk-aac.so.2
COPY --from=build /usr/lib/librav1e.so /usr/lib/librav1e.so

CMD ["/usr/local/bin/ffmpeg"]
