FROM nginx:1.27-alpine

# Optional: add curl for quick debugging if you exec into the container elsewhere
RUN apk add --no-cache curl

# Nginx config + startup template
COPY nginx.conf.template /etc/nginx/templates/egress.conf.template
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 18001-18010

ENTRYPOINT ["/entrypoint.sh"]
