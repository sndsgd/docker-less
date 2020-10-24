FROM alpine:3.12
LABEL maintainer sndsgd

ARG NODE_VERSION
ARG LESS_VERSION

RUN \
  apk add --update --no-cache \
    nodejs=${NODE_VERSION} \
    nodejs-npm \
  && npm install -g less@${LESS_VERSION}

ENTRYPOINT ["/usr/bin/lessc"]
