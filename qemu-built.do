#!/bin/bash -x
redo-ifchange config.sh prep qemu.source
exec 1>&2
. ./config.sh
cd qemu.source

KERNEL_SOURCE=/illumos
CTFBINDIR=$KERNEL_SOURCE/usr/src/tools/proto/root_i386-nd/opt/onbld/bin/i386
export PATH=$PATH:$CTFBINDIR

# tell QEMU to use my cflags
export QEMU_CFLAGS=${CFLAGS}

./configure \
    --prefix=${SMARTDC} \
    --disable-bluez \
    --disable-brlapi \
    --disable-curl \
    --disable-sdl \
    --disable-curses \
    --disable-vnc-sasl \
    --disable-vnc-tls \
    --enable-debug \
    --enable-kvm \
    --enable-vnc-png \
    --audio-drv-list= \
    --enable-vnc-jpeg \
    --enable-trace-backend=dtrace \
    --enable-spice \
    --target-list="x86_64-softmmu" \
    --cpu=x86_64 && \
gmake V=1 all
