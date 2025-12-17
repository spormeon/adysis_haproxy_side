#!/bin/sh
set -eu

: "${SECRET_HEADER_NAME:?Missing SECRET_HEADER_NAME}"
: "${SECRET_HEADER_VALUE:?Missing SECRET_HEADER_VALUE}"

# Render the template loop for i=1..10
OUT=/etc/nginx/conf.d/egress.conf
TEMPLATE=/etc/nginx/templates/egress.conf.template

# Simple renderer for the specific {% for i in range(1, 11) %} loop above
# (Keeps the image tiny; no python/jinja needed)
awk -v shn="$SECRET_HEADER_NAME" -v shv="$SECRET_HEADER_VALUE" '
  function emit_server(i) {
    port = 18000 + i
    print "server {"
    print "  listen " port ";"
    print "  allow 127.0.0.1;"
    print "  deny all;"
    print "  location / {"
    print "    set $slot_host \"pbs-europe-" i ".adysis.com\";"
    print "    proxy_pass http://$slot_host;"
    print "    proxy_set_header Host $slot_host;"
    print "    proxy_set_header " shn " \"" shv "\";"
    print "    proxy_http_version 1.1;"
    print "    proxy_set_header Connection \"\";"
    print "    proxy_connect_timeout 2s;"
    print "    proxy_send_timeout 10s;"
    print "    proxy_read_timeout 10s;"
    print "  }"
    print "}"
    print ""
  }
  BEGIN {
    print "# Auto-generated; do not edit by hand"
    print ""
    for (i=1; i<=10; i++) emit_server(i)
  }
' > "$OUT"

exec nginx -g 'daemon off;'
