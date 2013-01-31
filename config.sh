export MAKEFLAGS="-j$(psrinfo | wc -l)"
export LC_ALL=C
export MY_PREFIX=/opt/local
export MY_LIBS=${MY_PREFIX}/lib/amd64
export MY_INCS=${MY_PREFIX}/include
export LDFLAGS="-m64 -L${MY_LIBS}"
export CFLAGS="-m64 -I${MY_INCS}"
export CXXLAGS=${CFLAGS}
export CPPFLAGS="-I${MY_INCS}"
export SMARTDC=/smartdc2

export QEMU_VERSION=qemu-1.1.2
export VERSION=1.0
