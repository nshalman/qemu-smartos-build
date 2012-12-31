spice=spice-0.12.2
spice_proto=spice-protocol-0.12.3
celt=celt-0.5.1.3
usbredir=usbredir-0.4.4

export MAKEFLAGS="-j$(psrinfo | wc -l)"
export LC_ALL=C
export MY_PREFIX=/opt/local
export MY_LIBS=${MY_PREFIX}/lib
export MY_INCS=${MY_PREFIX}/include
export LDFLAGS=-m64
export CFLAGS=-m64
