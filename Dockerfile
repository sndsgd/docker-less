ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}
LABEL maintainer sndsgd

ARG NODE_VERSION
ARG LESS_VERSION

RUN \
  apk add --update --no-cache nodejs=${NODE_VERSION} npm \
  && npm install -g less@${LESS_VERSION}

ENTRYPOINT ["/usr/local/bin/lessc"]
