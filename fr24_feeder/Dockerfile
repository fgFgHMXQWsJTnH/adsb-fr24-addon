ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL maintainer="YOUR_GITHUB_USERNAME"
LABEL description="FR24 ADS-B Feeder using dump1090-fa + fr24feed"

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    librtlsdr0 \
    rtl-sdr \
    wget \
    curl \
    ca-certificates \
    gnupg \
    socat \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Add FlightAware apt repo manually — their installer package refuses to run on
# Debian Trixie (the HA base image), but the packages themselves work fine.
# We extract just the GPG key from the .deb and write the source list ourselves.
RUN wget -q https://www.flightaware.com/adsb/piaware/files/packages/pool/piaware/f/flightaware-apt-repository/flightaware-apt-repository_1.1_all.deb \
        -O /tmp/fa-repo.deb \
    && dpkg-deb -x /tmp/fa-repo.deb /tmp/fa-repo \
    && mkdir -p /usr/share/keyrings \
    && cp /tmp/fa-repo/usr/share/keyrings/flightaware-apt-repository.gpg \
          /usr/share/keyrings/flightaware-apt-repository.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/flightaware-apt-repository.gpg] https://flightaware.com/adsb/piaware/files/packages bullseye piaware" \
       > /etc/apt/sources.list.d/flightaware.list \
    && rm -rf /tmp/fa-repo /tmp/fa-repo.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends dump1090-fa \
    && rm -rf /var/lib/apt/lists/*

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
