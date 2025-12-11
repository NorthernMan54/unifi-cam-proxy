ARG version=3.11
ARG tag=${version}-alpine3.20

FROM python:${tag} AS builder
WORKDIR /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apk add --update \
    cargo \
    git \
    gcc \
    g++ \
    jpeg-dev \
    libc-dev \
    linux-headers \
    musl-dev \
    patchelf \
    rust \
    zlib-dev

RUN pip install -U pip wheel setuptools maturin
COPY requirements.txt .
RUN pip install -r requirements.txt --no-build-isolation


FROM python:${tag}
WORKDIR /app

ARG version
ARG FFMPEG_VERSION=2.2.0
ARG TARGETARCH

COPY --from=builder \
    /usr/local/lib/python${version}/site-packages \
    /usr/local/lib/python${version}/site-packages

RUN apk add --update netcat-openbsd libusb-dev curl

# Install homebridge ffmpeg for Alpine
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    FFMPEG_ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    FFMPEG_ARCH="aarch64"; \
    elif [ "$TARGETARCH" = "arm" ]; then \
    FFMPEG_ARCH="armv7l"; \
    else \
    FFMPEG_ARCH="x86_64"; \
    fi && \
    curl -L "https://github.com/homebridge/ffmpeg-for-homebridge/releases/download/v${FFMPEG_VERSION}/ffmpeg-alpine-${FFMPEG_ARCH}.tar.gz" \
    -o /tmp/ffmpeg.tar.gz && \
    tar -xzf /tmp/ffmpeg.tar.gz -C / --strip-components=0 && \
    chmod +x /usr/local/bin/ffmpeg && \
    rm /tmp/ffmpeg.tar.gz && \
    apk del curl

COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
