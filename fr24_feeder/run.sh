#!/usr/bin/with-contenv bashio

# ── Read addon options ────────────────────────────────────────────────────────
SERIAL=$(bashio::config 'serial')
LAT=$(bashio::config 'lat')
LON=$(bashio::config 'lon')
ALT_M=$(bashio::config 'alt_m')
GAIN=$(bashio::config 'gain')
FR24_KEY=$(bashio::config 'fr24_key')

bashio::log.info "Starting FR24 ADS-B Feeder"
bashio::log.info "RTL-SDR serial: ${SERIAL}"
bashio::log.info "Location: ${LAT}, ${LON} @ ${ALT_M}m"

# ── Validate required options ─────────────────────────────────────────────────
if bashio::var.is_empty "${FR24_KEY}"; then
    bashio::log.fatal "fr24_key is required — set it in addon options"
    exit 1
fi

# ── fr24feed is at /usr/bin/fr24feed (installed from tarball) ─────────────
FR24BIN=/usr/bin/fr24feed

# ── Build gain argument ───────────────────────────────────────────────────────
if [ "${GAIN}" = "auto" ]; then
    GAIN_ARG="--gain -10"
else
    GAIN_ARG="--gain ${GAIN}"
fi

# ── Write fr24feed config ─────────────────────────────────────────────────────
mkdir -p /etc
cat > /etc/fr24feed.ini << EOF
receiver=beast-tcp
host=127.0.0.1:30005
fr24key=${FR24_KEY}
bs=no
raw=no
logmode=0
log=/tmp/fr24feed.log
mlat=yes
mlat-without-gps=no
EOF
bashio::log.info "fr24feed config written"

# ── Start readsb ──────────────────────────────────────────────────────────────
# Correct flags per readsb manpage:
#   --device-type rtlsdr  (selects RTL-SDR backend)
#   --serial=<sn>         (selects by serial string, not index)
#   --net-bo-port         (Beast output port)
bashio::log.info "Starting readsb (serial: ${SERIAL})"

readsb \
    --device-type=rtlsdr \
    --device="${SERIAL}" \
    ${GAIN_ARG} \
    --lat="${LAT}" \
    --lon="${LON}" \
    --altitude="${ALT_M}" \
    --net \
    --net-bo-port=30005 \
    --net-ro-port=30002 \
    --net-sbs-port=30003 \
    --write-json=/run/adsb \
    --write-json-every=1 \
    --quiet &

READSB_PID=$!
bashio::log.info "readsb started (PID: ${READSB_PID})"

# ── Wait for Beast port 30005 ─────────────────────────────────────────────────
bashio::log.info "Waiting for readsb Beast port 30005..."
for i in $(seq 1 30); do
    if socat /dev/null TCP:127.0.0.1:30005,connect-timeout=1 2>/dev/null; then
        bashio::log.info "Beast port ready"
        break
    fi
    sleep 1
done

# ── Start fr24feed ────────────────────────────────────────────────────────────
bashio::log.info "Starting fr24feed"
"${FR24BIN}" --config=/etc/fr24feed.ini &
FR24_PID=$!
bashio::log.info "fr24feed started (PID: ${FR24_PID})"

# ── Serve aircraft.json on port 8080 ─────────────────────────────────────────
bashio::log.info "Starting aircraft.json HTTP server on port 8080"
python3 -m http.server 8080 --directory /run/adsb &
HTTP_PID=$!
bashio::log.info "HTTP server started (PID: ${HTTP_PID})"

# ── Monitor processes ─────────────────────────────────────────────────────────
bashio::log.info "All services started. Monitoring..."

while true; do
    if ! kill -0 "${READSB_PID}" 2>/dev/null; then
        bashio::log.fatal "readsb died — restarting addon"
        exit 1
    fi
    if ! kill -0 "${FR24_PID}" 2>/dev/null; then
        bashio::log.error "fr24feed died — restarting"
        "${FR24BIN}" --config=/etc/fr24feed.ini &
        FR24_PID=$!
        bashio::log.info "fr24feed restarted (PID: ${FR24_PID})"
    fi
    if ! kill -0 "${HTTP_PID}" 2>/dev/null; then
        bashio::log.error "HTTP server died — restarting"
        python3 -m http.server 8080 --directory /run/adsb &
        HTTP_PID=$!
    fi
    sleep 30
done
