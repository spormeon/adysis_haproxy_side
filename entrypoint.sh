# #!/bin/sh
# set -eu

# : "${SECRET_HEADER_NAME:?must be set}"
# : "${SECRET_HEADER_VALUE:?must be set}"
# : "${REGION_PREFIX:?must be set (e.g. pbs-europe, pbs-northamerica, pbs-southamerica)}"

# # Derive probe host from region prefix (slot 1) unless explicitly overridden
# READY_PROBE_HOST="${READY_PROBE_HOST:-${REGION_PREFIX}-1.adysis.com}"

# export SECRET_HEADER_NAME SECRET_HEADER_VALUE READY_PROBE_HOST REGION_PREFIX

# # 1) Health listener for Bunny checks
# envsubst '${SECRET_HEADER_NAME} ${SECRET_HEADER_VALUE} ${READY_PROBE_HOST}' \
#   < /etc/nginx/health.conf.template > /etc/nginx/conf.d/00-health.conf

# # 2) Egress listener blocks
# OUT="/etc/nginx/conf.d/egress.conf"
# : > "$OUT"

# gen_region () {
#   region_prefix="$1"
#   base_port="$2"

#   i=1
#   while [ $i -le 10 ]; do
#     export PORT=$((base_port + i))
#     export SLOT_HOST="${region_prefix}-${i}.adysis.com"

#     envsubst '${PORT} ${SLOT_HOST} ${SECRET_HEADER_NAME} ${SECRET_HEADER_VALUE}' \
#       < /etc/nginx/nginx.conf.template >> "$OUT"
#     printf "\n" >> "$OUT"

#     i=$((i + 1))
#   done
# }

# gen_region "pbs-europe"       18000
# gen_region "pbs-northamerica" 15000
# gen_region "pbs-southamerica" 16000

# exec nginx -g "daemon off;"


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

gen_region "pbs-europe"       18000
gen_region "pbs-northamerica" 15000
gen_region "pbs-southamerica" 16000

nginx -t
exec nginx -g "daemon off;"


