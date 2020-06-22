FROM alpine:3.12
LABEL maintainer sndsgd

ARG NODE_VERSION=12.17.0-r0
ARG LESS_VERSION=3.11.3

RUN apk add --update --no-cache nodejs=${NODE_VERSION} nodejs-npm \
    && npm install -g less@${LESS_VERSION}

ENTRYPOINT ["lessc"]
