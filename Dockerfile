ARG BUILD_DATE
ARG VCS_REF

FROM hhftechnology/alpine:3.19 as build

RUN apk add --no-cache \
    curl \
    build-base \
    openssl \
    openssl-dev \
    zlib-dev \
    linux-headers \
    pcre-dev \
    luajit \
    luajit-dev \
    ffmpeg \
    ffmpeg-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev

RUN mkdir nginx nginx-vod-module nginx-lua-module ngx_devel_kit nginx-rtmp-module

# Updated versions
ENV NGINX_VERSION=1.26.1
ENV VOD_MODULE_VERSION=1.33
ENV LUA_MODULE_VERSION=v0.10.25
ENV DEV_MODULE_VERSION=v0.3.3
ENV RTMP_MODULE_VERSION=v1.2.2

# Download and extract NGINX and modules
RUN curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C nginx --strip 1 -xz
RUN curl -sL https://github.com/kaltura/nginx-vod-module/archive/${VOD_MODULE_VERSION}.tar.gz | tar -C nginx-vod-module --strip 1 -xz
RUN curl -sL https://github.com/openresty/lua-nginx-module/archive/${LUA_MODULE_VERSION}.tar.gz | tar -C nginx-lua-module --strip 1 -xz
RUN curl -sL https://github.com/simpl/ngx_devel_kit/archive/${DEV_MODULE_VERSION}.tar.gz | tar -C ngx_devel_kit --strip 1 -xz
RUN curl -sL https://github.com/arut/nginx-rtmp-module/archive/${RTMP_MODULE_VERSION}.tar.gz | tar -C nginx-rtmp-module --strip 1 -xz

# Updated LuaJIT paths for Alpine 3.19
ENV LUAJIT_INC=/usr/include/luajit-2.1/
ENV LUAJIT_LIB=/usr/lib

WORKDIR /nginx
RUN ./configure \
    --prefix=/usr/local/nginx \
    --with-ld-opt="-Wl,-rpath,/usr/lib/libluajit-5.1.so" \
    --add-module=../nginx-vod-module \
    --add-module=../ngx_devel_kit \
    --add-module=../nginx-lua-module \
    --add-module=../nginx-rtmp-module \
    --with-file-aio \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_stub_status_module \
    --with-cc-opt="-O3"

RUN make -j$(nproc)
RUN make install

# Final stage
FROM alpine:3.19

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="HHF Technology <discourse@hhf.technology>" \
    architecture="amd64/x86_64" \
    nginx-version="${NGINX_VERSION}" \
    alpine-version="3.19" \
    build="10-Dec-2024" \
    org.opencontainers.image.title="alpine-nginx-video-stream" \
    org.opencontainers.image.description="NGINX Container with VOD and RTMP modules running on Alpine Linux" \
    org.opencontainers.image.authors="HHF Technology <discourse@hhf.technology>" \
    org.opencontainers.image.vendor="HHF Technology" \
    org.opencontainers.image.version="${NGINX_VERSION}" \
    org.opencontainers.image.url="https://hub.docker.com/r/hhftechnology/alpine-nginx-video-stream/" \
    org.opencontainers.image.source="https://github.com/hhftechnology/alpine-nginx-video-stream" \
    org.opencontainers.image.base.name="docker.io/hhftechnology/alpine:3.19" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

RUN apk add --no-cache \
    ca-certificates \
    openssl \
    pcre \
    zlib \
    luajit \
    ffmpeg \
    libjpeg-turbo && \
    addgroup -S nginx && \
    adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

COPY --from=build /usr/local/nginx /usr/local/nginx
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
RUN rm -rf /usr/local/nginx/html /usr/local/nginx/conf/*.default && \
    mkdir -p /var/log/nginx && \
    mkdir -p /tmp/hls && \
    mkdir -p /tmp/dash && \
    mkdir -p /var/media && \
    chown -R nginx:nginx /var/log/nginx /tmp/hls /tmp/dash /var/media

VOLUME ["/var/media", "/var/log/nginx"]
EXPOSE 80 443 1935

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]
CMD ["-g", "daemon off;"]