FROM alpine:3

LABEL org.opencontainers.image.source = "https://github.com/yogendra/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"

RUN mkdir -p /config
ADD packaging/entrypoint /entrypoint
ADD src/* /config/

USER nobody
ENTRYPOINT ["/entrypoint"]
