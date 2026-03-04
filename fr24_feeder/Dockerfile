ARG BUILD_FROM
FROM ${BUILD_FROM}

LABEL maintainer="fgFgHMXQWsJTnH"
LABEL description="FR24 ADS-B Feeder using readsb (built from source) + fr24feed"

# ── Dependencies ─────────────────────────────────────────────────────────────
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
    debhelper \
    fakeroot \
    help2man \
    pkg-config \
    libncurses-dev \
    zlib1g-dev \
    libzstd-dev \
    adduser \
    socat \
    python3 \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ── Build readsb from source with RTL-SDR support ────────────────────────────
RUN git clone --depth 20 https://github.com/wiedehopf/readsb.git /tmp/readsb \
    && cd /tmp/readsb \
    && export DEB_BUILD_OPTIONS=noddebs \
    && dpkg-buildpackage -b -ui -uc -us --build-profiles=rtlsdr \
    && dpkg -i /tmp/readsb_*.deb \
    && rm -rf /tmp/readsb /tmp/readsb_* /tmp/readsb-*.deb

# ── Install fr24feed from tarball (avoids dpkg dep issues) ───────────────────
# Tarball contains a standalone binary — no package manager needed.
RUN wget -q https://repo-feed.flightradar24.com/linux_x86_64_binaries/fr24feed_1.0.38-0_amd64.tgz \
        -O /tmp/fr24feed.tgz \
    && tar -xzf /tmp/fr24feed.tgz -C /tmp \
    && cp /tmp/fr24feed_*/fr24feed /usr/bin/fr24feed \
    && chmod +x /usr/bin/fr24feed \
    && rm -rf /tmp/fr24feed*

# ── JSON output dir ───────────────────────────────────────────────────────────
RUN mkdir -p /run/adsb

# ── Startup script ────────────────────────────────────────────────────────────
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
