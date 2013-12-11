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
pkgin -y in png spice-protocol usbredir

# XXX separate out libspice installation due to need to manually downgrade
pkg_info libspice &>/dev/null || pkgin -y in libspice

# XXX downgrade to spice 0.12.2
pkg_info libspice | grep -q libspice-0.12.2 || \
	{ \
	pkgin -y rm libpsice && \
	pkg_add <(curl http://pkgsrc.joyent.com/packages/SmartOS/2013Q1/x86_64/All/libspice-0.12.2.tgz) && \
	echo "Manually downgraded to libspice-0.12.2 due to known issue with later versions" ; \
	}
