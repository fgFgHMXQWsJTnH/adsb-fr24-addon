# ── Stage 1: Build ────────────────────────────────────────────────────────────
# Full workshop — compilers, headers, build tools.
# None of this ends up in the final image.
ARG BUILD_FROM
FROM ${BUILD_FROM} AS builder

# All build-time dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0-dev \
    librtlsdr-dev \
    wget \
    ca-certificates \
    git \
    build-essential \
    debhelper \
    fakeroot \
    help2man \
    pkg-config \
    libncurses-dev \
    zlib1g-dev \
    libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

# Build readsb — exactly as before, nothing changes here
RUN git clone --depth 20 https://github.com/wiedehopf/readsb.git /tmp/readsb \
    && cd /tmp/readsb \
    && export DEB_BUILD_OPTIONS=noddebs \
    && dpkg-buildpackage -b -ui -uc -us --build-profiles=rtlsdr \
    && dpkg -i /tmp/readsb_*.deb \
    && rm -rf /tmp/readsb /tmp/readsb_* /tmp/readsb-*.deb

# Download fr24feed binary
RUN wget -q https://repo-feed.flightradar24.com/linux_binaries/fr24feed_1.0.56-0_amd64.tgz \
        -O /tmp/fr24feed.tgz \
    && tar -xzf /tmp/fr24feed.tgz -C /tmp \
    && cp /tmp/fr24feed_amd64/fr24feed /usr/bin/fr24feed \
    && chmod +x /usr/bin/fr24feed \
    && rm -rf /tmp/fr24feed*


# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
# Clean slate — only what's needed to actually run.
FROM ${BUILD_FROM}

LABEL maintainer="fgFgHMXQWsJTnH"
LABEL description="FR24 ADS-B Feeder using readsb (built from source) + fr24feed"

# Runtime libraries only (from ldd /usr/bin/readsb output)
RUN apt-get update && apt-get install -y --no-install-recommends \
    librtlsdr0 \
    libusb-1.0-0 \
    libudev1 \
    libzstd1 \
    libncurses6 \
    libtinfo6 \
    libcap2 \
    zlib1g \
    wget \
    ca-certificates \
    python3 \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Copy the two binaries from the build stage — nothing else
COPY --from=builder /usr/bin/readsb /usr/bin/readsb
COPY --from=builder /usr/bin/fr24feed /usr/bin/fr24feed

# JSON output dir
RUN mkdir -p /run/adsb

# Startup script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
