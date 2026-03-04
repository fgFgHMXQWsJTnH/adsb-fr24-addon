ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL maintainer="fgFgHMXQWsJTnH"
LABEL description="FR24 ADS-B Feeder using readsb (built from source) + fr24feed"

# ── Dependencies ────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    librtlsdr0 \
    librtlsdr-dev \
    rtl-sdr \
    wget \
    curl \
    ca-certificates \
    git \
    build-essential \
    pkg-config \
    socat \
    python3 \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ── Build readsb from source with RTL-SDR support ───────────────────────────
# Avoids all Trixie/dump1090-fa/FlightAware apt repo issues entirely.
RUN git clone --depth 1 https://github.com/wiedehopf/readsb.git /tmp/readsb \
    && cd /tmp/readsb \
    && make RTLSDR=yes BLADERF=no HACKRF=no SOAPYSDR=no \
    && cp readsb /usr/local/bin/readsb \
    && rm -rf /tmp/readsb

# ── Install fr24feed binary ──────────────────────────────────────────────────
# Using the versioned .deb for reproducibility. Update version as needed.
# Check https://repo-feed.flightradar24.com for latest.
RUN wget -q https://repo-feed.flightradar24.com/linux_x86_64/fr24feed_1.0.38-0_amd64.deb \
        -O /tmp/fr24feed.deb \
    && dpkg -i /tmp/fr24feed.deb || apt-get install -f -y \
    && rm /tmp/fr24feed.deb \
    && rm -rf /var/lib/apt/lists/*

# ── JSON output dir ──────────────────────────────────────────────────────────
RUN mkdir -p /run/adsb

# ── Startup script ───────────────────────────────────────────────────────────
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
