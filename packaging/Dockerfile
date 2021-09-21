FROM alpine:3

LABEL org.opencontainers.image.source = "https://github.com/yogendra/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"

ADD src/* /
ADD packaging/entrypoint /entrypoint

USER nobody
CMD /entrypoint
