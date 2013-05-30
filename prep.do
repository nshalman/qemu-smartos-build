#!/bin/bash -x
exec 1>&2

pkgin -y up

# need git to get code
pkgin -y in scmgit bsdtar

# build tools
pkgin -y in gcc47 gmake libtool-base automake pkg-config

# onbld tools from illumos
curl http://www.shalman.org/spice/2012Q4-multiarch-onbld/onbld-0.0.1.tgz | tar xzv -C /opt/local bin lib

# dependencies
pkgin -y in png spice-protocol libspice usbredir
