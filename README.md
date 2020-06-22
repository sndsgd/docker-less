# sndsgd/docker-less

A docker image with [LESS](http://lesscss.org/).


### Build

If you want to build the image locally, you can follow these steps:

1. Checkout this repo
1. Run `make build-image`


### Usage

    docker run --rm -v $(pwd):$(pwd) -w $(pwd) sndsgd/less input.less output.css
