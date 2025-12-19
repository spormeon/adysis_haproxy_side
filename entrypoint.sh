#!/bin/sh
set -eu

: "${SECRET_HEADER_NAME:?must be set}"
: "${SECRET_HEADER_VALUE:?must be set}"
: "${READY_PROBE_HOST:?must be set (e.g. pbs-europe-1.adysis.com)}"

# 1) Health listener for Bunny checks
export SECRET_HEADER_NAME SECRET_HEADER_VALUE READY_PROBE_HOST
envsubst '${SECRET_HEADER_NAME} ${SECRET_HEADER_VALUE} ${READY_PROBE_HOST}' \
  < /etc/nginx/health.conf.template > /etc/nginx/conf.d/00-health.conf

# 2) Egress listener blocks (18001..18010)
OUT="/etc/nginx/conf.d/egress.conf"
: > "$OUT"

gen_region () {
  region_prefix="$1"   # e.g. "pbs-northamerica" or whatever your real name is
  base_port="$2"       # e.g. 15000

  i=1
  while [ $i -le 10 ]; do
    export PORT=$((base_port + i))
    export SLOT_HOST="${region_prefix}-${i}.adysis.com"

    envsubst '${PORT} ${SLOT_HOST} ${SECRET_HEADER_NAME} ${SECRET_HEADER_VALUE}' \
      < /etc/nginx/nginx.conf.template >> "$OUT"
    printf "\n" >> "$OUT"

    i=$((i + 1))
  done
}

# EU 18001..18010
gen_region "pbs-europe"       18000

# NA 15001..15010
gen_region "pbs-northamerica" 15000

# SA 16001..16010
gen_region "pbs-southamerica" 16000


exec nginx -g "daemon off;"
