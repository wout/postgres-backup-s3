# Pin the version becuase pg_dump from a newer major can dump older servers,
# but restore must run on a matching-or-newer server, so match exactly.
ARG PG_VERSION=17
FROM postgres:${PG_VERSION}-alpine

ARG SUPERCRONIC_VERSION=0.2.33
ARG TARGETARCH

RUN apk add --no-cache age rclone tzdata bash ca-certificates curl \
  && curl -fsSL -o /usr/local/bin/supercronic \
  "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-${TARGETARCH}" \
  && chmod +x /usr/local/bin/supercronic \
  && apk del curl

COPY entrypoint.sh backup.sh restore.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh \
  /usr/local/bin/backup.sh \
  /usr/local/bin/restore.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
