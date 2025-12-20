#!/bin/sh
set -eu

: "${SECRET_HEADER_NAME:?must be set}"
: "${SECRET_HEADER_VALUE:?must be set}"

export SECRET_HEADER_NAME SECRET_HEADER_VALUE

# 1) Health listener for Bunny checks
cp /etc/nginx/health.conf.template /etc/nginx/conf.d/00-health.conf

# 2) Egress listener blocks
OUT="/etc/nginx/conf.d/egress.conf"
: > "$OUT"

gen_region () {
  region_prefix="$1"
  base_port="$2"

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

gen_region "pbs-northamerica" 16000
gen_region "pbs-southamerica" 17000
gen_region "pbs-europe"       18000
gen_region "pbs-africa"       19000
gen_region "pbs-middleeast"   20000
gen_region "pbs-asia"         21000
gen_region "pbs-oceania"      22000

nginx -t
exec nginx -g "daemon off;"


