#!/usr/bin/with-contenv bashio

# ── Read addon options ────────────────────────────────────────────────────────
SERIAL=$(bashio::config 'serial')
LAT=$(bashio::config 'lat')
LON=$(bashio::config 'lon')
ALT_M=$(bashio::config 'alt_m')
GAIN=$(bashio::config 'gain')
FR24_KEY=$(bashio::config 'fr24_key')
FA_FEEDER_ID=$(bashio::config 'flightaware_feeder_id')
ADSBFI_UUID=$(bashio::config 'adsbfi_uuid')
ADSBEXCHANGE_UUID=$(bashio::config 'adsbexchange_uuid')

bashio::log.info "Starting FR24 ADS-B Feeder"
bashio::log.info "RTL-SDR serial: ${SERIAL}"
bashio::log.info "Location: ${LAT}, ${LON} @ ${ALT_M}m"

# ── Validate required options ─────────────────────────────────────────────────
if bashio::var.is_empty "${FR24_KEY}"; then
    bashio::log.fatal "fr24_key is required — set it in addon options"
    exit 1
fi

if [ "${LAT}" = "0.0" ] && [ "${LON}" = "0.0" ]; then
    bashio::log.warning "lat/lon are 0.0 — MLAT will not work. Set your real coordinates."
fi

# ── Build readsb gain argument ────────────────────────────────────────────────
if [ "${GAIN}" = "auto" ]; then
    GAIN_ARG="--gain -10"
else
    GAIN_ARG="--gain ${GAIN}"
fi

# ── Write fr24feed config (injected at runtime, never stored in repo) ─────────
mkdir -p /etc/fr24feed
cat > /etc/fr24feed/fr24feed.ini << EOF
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
bashio::log.info "Starting readsb (serial: ${SERIAL})"

readsb \
    --device-type rtlsdr \
    --device="${SERIAL}" \
    ${GAIN_ARG} \
    --net \
    --net-beast-port 30005 \
    --net-ro-port 30002 \
    --net-sbs-port 30003 \
    --lat "${LAT}" \
    --lon "${LON}" \
    --max-range 450 \
    --json-location-accuracy 2 \
    --write-json /run/readsb \
    --net-http-port 8080 \
    --quiet &

READSB_PID=$!
bashio::log.info "readsb started (PID: ${READSB_PID})"

# ── Wait for readsb Beast port to be ready ────────────────────────────────────
bashio::log.info "Waiting for readsb Beast port 30005..."
for i in $(seq 1 30); do
    if socat /dev/null TCP:127.0.0.1:30005,connect-timeout=1 2>/dev/null; then
        bashio::log.info "readsb Beast port ready"
        break
    fi
    sleep 1
done

# ── Start fr24feed ────────────────────────────────────────────────────────────
bashio::log.info "Starting fr24feed"
fr24feed --config=/etc/fr24feed/fr24feed.ini &
FR24_PID=$!
bashio::log.info "fr24feed started (PID: ${FR24_PID})"

# ── Optional: FlightAware piaware ─────────────────────────────────────────────
if ! bashio::var.is_empty "${FA_FEEDER_ID}"; then
    bashio::log.info "Starting FlightAware piaware feed"
    piaware \
        --receiver-type beast-tcp \
        --beast-tcp-host 127.0.0.1 \
        --beast-tcp-port 30005 \
        --feeder-id "${FA_FEEDER_ID}" \
        --lat "${LAT}" \
        --lon "${LON}" &
    bashio::log.info "piaware started"
fi

# ── Optional: adsb.fi ─────────────────────────────────────────────────────────
if ! bashio::var.is_empty "${ADSBFI_UUID}"; then
    bashio::log.info "Starting adsb.fi feed"
    socat TCP:feed.adsb.fi:30004,keepalive TCP:127.0.0.1:30005 &
    bashio::log.info "adsb.fi feed started"
fi

# ── Optional: ADS-B Exchange ──────────────────────────────────────────────────
if ! bashio::var.is_empty "${ADSBEXCHANGE_UUID}"; then
    bashio::log.info "Starting ADS-B Exchange feed"
    socat TCP:feed.adsbexchange.com:30004,keepalive TCP:127.0.0.1:30005 &
    bashio::log.info "ADS-B Exchange feed started"
fi

# ── Monitor processes ─────────────────────────────────────────────────────────
bashio::log.info "All services started. Monitoring..."

while true; do
    if ! kill -0 "${READSB_PID}" 2>/dev/null; then
        bashio::log.fatal "readsb died — restarting addon"
        exit 1
    fi
    if ! kill -0 "${FR24_PID}" 2>/dev/null; then
        bashio::log.error "fr24feed died — restarting fr24feed"
        fr24feed --config=/etc/fr24feed/fr24feed.ini &
        FR24_PID=$!
        bashio::log.info "fr24feed restarted (PID: ${FR24_PID})"
    fi
    sleep 30
done