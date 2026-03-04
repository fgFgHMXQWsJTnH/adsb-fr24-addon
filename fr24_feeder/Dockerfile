ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL maintainer="YOUR_GITHUB_USERNAME"
LABEL description="FR24 ADS-B Feeder using readsb + fr24feed"

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    librtlsdr0 \
    rtl-sdr \
    wget \
    curl \
    ca-certificates \
    socat \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Add FlightAware apt repo and install dump1090-fa (built with RTL-SDR support)
RUN wget -q https://www.flightaware.com/adsb/piaware/files/packages/pool/piaware/f/flightaware-apt-repository/flightaware-apt-repository_1.1_all.deb -O /tmp/fa-repo.deb \
    && dpkg -i /tmp/fa-repo.deb \
    && rm /tmp/fa-repo.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends dump1090-fa \
    && rm -rf /var/lib/apt/lists/*

# Install fr24feed
# Check https://repo-feed.flightradar24.com for latest version before building
RUN wget -q https://repo-feed.flightradar24.com/linux_x86_64/fr24feed_1.0.38-0_amd64.deb -O /tmp/fr24feed.deb \
    && dpkg -i /tmp/fr24feed.deb || apt-get install -f -y \
    && rm /tmp/fr24feed.deb

# Copy startup script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
