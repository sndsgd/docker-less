# sndsgd/docker-less

A [LESS](http://lesscss.org/) docker image builder.

### Build

If you want to build the image locally, you can follow these steps:

1. Checkout this repo
1. Run `make image`

### Usage

```
docker run --rm \
  -u $(id -u):$(id -g) \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  ghcr.io/sndsgd/less input.less output.css
```
