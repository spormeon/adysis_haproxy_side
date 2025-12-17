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

i=1
while [ $i -le 10 ]; do
  export PORT=$((18000 + i))
  export SLOT_HOST="pbs-europe-${i}.adysis.com"

  envsubst '${PORT} ${SLOT_HOST} ${SECRET_HEADER_NAME} ${SECRET_HEADER_VALUE}' \
    < /etc/nginx/nginx.conf.template >> "$OUT"
  printf "\n" >> "$OUT"

  i=$((i + 1))
done

exec nginx -g "daemon off;"
