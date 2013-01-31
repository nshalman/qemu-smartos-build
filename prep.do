#!/bin/bash -x
exec 1>&2

cat > /opt/local/etc/pkgin/repositories.conf <<EOF
http://pkgsrc.smartos.org/packages/SmartOS/2012Q4-multiarch/All
http://www.shalman.org/spice/2012Q4-multiarch-spice
http://www.shalman.org/spice/2012Q4-multiarch-onbld
EOF

rm -rf /var/db/pkgin/
pkgin -y up

# need git to get code
pkgin -y in scmgit bsdtar

# build tools
pkgin -y in gcc47 gmake libtool-base automake pkg-config

# build tools I provide
pkgin -y in onbld

# dependencies
pkgin -y in png spice-protocol libspice usbredir
