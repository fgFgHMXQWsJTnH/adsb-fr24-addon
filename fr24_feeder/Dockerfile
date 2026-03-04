ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL maintainer="YOUR_GITHUB_USERNAME"
LABEL description="FR24 ADS-B Feeder using dump1090-fa + fr24feed"

# Install base dependencies + dump1090-fa build deps
# FlightAware's apt repo only supports up to Bookworm; on Trixie we build from source.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    librtlsdr0 \
    librtlsdr-dev \
    rtl-sdr \
    wget \
    curl \
    ca-certificates \
    git \
    build-essential \
    devscripts \
    debhelper \
    libbladerf-dev \
    libhackrf-dev \
    liblimesuite-dev \
    libusb-1.0-0-dev \
    pkg-config \
    libncurses5-dev \
    adduser \
    socat \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Build and install dump1090-fa from source using bookworm profile
# (FlightAware's own Trixie workaround — see abcd567a/piaware-ubuntu-debian-amd64)
RUN git clone --depth 1 https://github.com/flightaware/dump1090 /tmp/dump1090 \
    && cd /tmp/dump1090 \
    && ./prepare-build.sh bookworm \
    && cd package-bookworm \
    && dpkg-buildpackage -b --no-sign \
    && cd /tmp/dump1090 \
    && dpkg -i dump1090-fa_*.deb \
    && rm -rf /tmp/dump1090

# Install fr24feed
# Check https://repo-feed.flightradar24.com for latest version before building
RUN wget -q https://repo-feed.flightradar24.com/linux_x86_64/fr24feed_1.0.38-0_amd64.deb \
        -O /tmp/fr24feed.deb \
    && dpkg -i /tmp/fr24feed.deb || apt-get install -f -y \
    && rm /tmp/fr24feed.deb \
    && rm -rf /var/lib/apt/lists/*

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
