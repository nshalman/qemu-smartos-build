#!/bin/bash
redo-ifchange config.sh prep spice.source spice-protocol-built celt-built
exec 2>&1
. ./config.sh
cd spice.source
./configure --prefix=${MY_PREFIX} --libdir=${MY_LIBS} --disable-client --enable-smartcard=no &&\
gmake &&\
gmake install
