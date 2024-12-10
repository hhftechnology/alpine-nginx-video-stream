# Alpine NGINX Video Streaming Server

[![Docker Automated build](https://img.shields.io/docker/automated/hhftechnology/alpine-nginx-video-stream.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/hhftechnology/alpine-nginx-video-stream/)
[![Docker Pulls](https://img.shields.io/docker/pulls/hhftechnology/alpine-nginx-video-stream.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/hhftechnology/alpine-nginx-video-stream/)
[![Alpine Version](https://img.shields.io/badge/Alpine%20version-v3.19.0-green.svg?style=for-the-badge&logo=alpine-linux)](https://alpinelinux.org/)
[![NGINX Version](https://img.shields.io/badge/NGINX%20version-v1.26.1-green.svg?style=for-the-badge&logo=nginx)](https://nginx.org/)

A lightweight NGINX server optimized for video streaming, featuring VOD support, RTMP streaming, and thumbnail generation, all built on Alpine Linux for minimal footprint.

## Technical Specifications

- **Base Image**: Alpine Linux 3.19.0
- **Web Server**: NGINX 1.26.1
- **Image Size**: Optimized for minimal footprint
- **Streaming Protocols**: HLS, DASH, RTMP
- **Video Processing**: Thumbnail generation, VOD support

## Supported Architectures

- `amd64`/`x86_64`: 64-bit Intel/AMD
- `arm64v8`/`aarch64`: 64-bit ARM (ARMv8)
- `arm32v7`/`armhf`: 32-bit ARM (ARMv7)

## Container Configuration

### Volume Mount Points
- `/var/media`: Video files and streaming content
- `/var/log/nginx`: NGINX logs
- `/etc/nginx/conf.d/`: Custom configuration files

### Network Ports
- `80`: HTTP port
- `443`: HTTPS port (configured but disabled by default)
- `1935`: RTMP port

### Environment Variables

#### Optional Variables
- `WORKER_PROCESSES`: Number of worker processes (default: auto)
- `WORKER_CONNECTIONS`: Maximum connections per worker (default: 1024)
- `CLIENT_MAX_BODY_SIZE`: Maximum upload size (default: 10m)

## Deployment Examples

### Basic Docker Run
```bash
docker run -d \
  --name nginx-streaming \
  -p 80:80 \
  -p 1935:1935 \
  -v media:/var/media \
  -v logs:/var/log/nginx \
  hhftechnology/alpine-nginx-video-stream:latest
```

### Docker Compose Configuration
```yaml
version: '3.8'

services:
  nginx-streaming:
    image: hhftechnology/alpine-nginx-video-stream:latest
    ports:
      - "80:80"
      - "1935:1935"
    volumes:
      - ./media:/var/media
      - ./logs:/var/log/nginx
      - ./custom.conf:/etc/nginx/conf.d/custom.conf:ro
    environment:
      - WORKER_PROCESSES=auto
      - WORKER_CONNECTIONS=1024
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

volumes:
  media:
    driver: local
  logs:
    driver: local
```

### Docker Swarm Deployment
```bash
docker service create \
  --name nginx-streaming \
  --publish 80:80 \
  --publish 1935:1935 \
  --mount type=volume,source=media,target=/var/media \
  --mount type=volume,source=logs,target=/var/log/nginx \
  --replicas 1 \
  hhftechnology/alpine-nginx-video-stream:latest
```

## Streaming Configuration

### RTMP Configuration
```nginx
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;
            hls on;
            hls_path /var/media/hls;
            dash on;
            dash_path /var/media/dash;
        }
    }
}
```

### HLS Configuration
```nginx
location /hls {
    types {
        application/vnd.apple.mpegurl m3u8;
        video/mp2t ts;
    }
    root /var/media;
    add_header Cache-Control no-cache;
    add_header Access-Control-Allow-Origin *;
}
```

## Streaming Examples

### Push RTMP Stream
```bash
ffmpeg -i input.mp4 -c:v copy -c:a aac -f flv rtmp://your-server:1935/live/stream
```

### Play Streams
- HLS: `http://your-server/hls/stream.m3u8`
- DASH: `http://your-server/dash/stream.mpd`
- VOD: `http://your-server/vod/video.mp4`

### Generate Thumbnail
```
http://your-server/thumb?video=example.mp4&time=30&width=320&height=240
```

## Performance Tuning

### Worker Configuration
```nginx
worker_processes auto;
worker_rlimit_nofile 65535;
events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}
```

### Buffer Settings
```nginx
http {
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;
}
```

## Security Considerations

1. Implement SSL/TLS for secure streaming
2. Configure proper access controls
3. Use secure RTMP keys
4. Monitor streaming activity
5. Regular security updates
6. Implement rate limiting
7. Configure proper file permissions

## Monitoring & Logging

- Access logs: `/var/log/nginx/access.log`
- Error logs: `/var/log/nginx/error.log`
- RTMP statistics: `http://your-server/stat`
- Health check: `http://your-server/health`

## Support & Contributing

- Issues: [GitHub Issues](https://github.com/hhftechnology/alpine-nginx-video-stream/issues)
- Forum: [HHF Technology Forum](https://forum.hhf.technology)
- Contribute: Submit PRs to our [GitHub repository](https://github.com/hhftechnology/alpine-nginx-video-stream)

## License

This project is licensed under the MIT License - see the LICENSE file for details.