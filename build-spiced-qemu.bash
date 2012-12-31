#!/bin/bash -x

# need git to get code
pkgin -y in scmgit

# build tools
pkgin -y in python27 gcc-compiler gmake libtool-base automake pkg-config

# dependencies
pkgin -y in pixman jpeg libogg glib2 png

# We need pyparsing to fully build the source tree
STAMPS=/root/stamps
mkdir -p ${STAMPS}

if [[ ! -e ${STAMPS}/distribute ]]; then
  curl http://python-distribute.org/distribute_setup.py | python && \
	touch ${STAMPS}/distribute || exit 1
fi

if [[ ! -e ${STAMPS}/pip ]]; then
	curl https://raw.github.com/pypa/pip/master/contrib/get-pip.py | python && \
	touch ${STAMPS}/pip || exit 1
fi

if [[ ! -e ${STAMPS}/pyparsing ]]; then
	pip install pyparsing && \
	touch ${STAMPS}/pyparsing || exit 1
fi

# Start building things

# Go faster!
export MAKEFLAGS="-j$(psrinfo | wc -l)"

export LC_ALL=C
MY_PREFIX=/opt/local
MY_LIBS=${MY_PREFIX}/lib
MY_INCS=${MY_PREFIX}/include

CELTDIR="${PWD}/celt-0.5.1.3"
if [[ ! -d ${CELTDIR} ]]; then
  (curl -L -k http://downloads.us.xiph.org/releases/celt/celt-0.5.1.3.tar.gz | \
        gtar -zxf -)
    if [[ $? != "0" || ! -d ${CELTDIR} ]]; then
        echo "Failed to get celt-0.5.1.3"
        rm -rf ${CELTDIR}
        exit 1
    fi
fi

if [[ ! -e ${MY_INCS}/celt051 ]]; then
    (cd ${CELTDIR} && \
        LDFLAGS=-m64 CFLAGS=-m64 ./configure --prefix=${MY_PREFIX} && \
        gsed '/DIR/{s/ tests//}' -i Makefile &&
        gmake && \
        gmake install)
    if [[ $? != "0" || ! -d ${MY_INCS}/celt051 ]]; then
        echo "Failed to build celt."
        exit 1
    fi
fi

SPICEDIR=${PWD}/spice
if [[ ! -d ${SPICEDIR} ]]; then
	(git clone git://anongit.freedesktop.org/spice/spice.git)
    if [[ $? != "0" || ! -d ${SPICEDIR} ]]; then
        echo "Failed to get spice."
        rm -rf ${SPICEDIR}
        exit 1
    fi
fi

if [[ ! -e ${MY_LIBS}/libspice-server.so ]]; then
	  echo "Running autogen.sh"
    (cd ${SPICEDIR} && \
        NOCONFIGURE=1 ./autogen.sh ) && \
    (cd ${SPICEDIR}/spice-common/spice-protocol && \
        ./configure --prefix=/opt/local && \
        gmake install) && \
    (cd ${SPICEDIR} && \
        LDFLAGS=-m64 CFLAGS=-m64 ./configure --prefix=/opt/local --disable-client --enable-smartcard=no && \
        gmake && \
        gmake install)
    if [[ $? != "0" || ! -e ${MY_LIBS}/libspice-server.so ]]; then
        echo "Failed to build spice."
        exit 1
    fi
fi

USBREDIR=${PWD}/usbredir
if [[ ! -d ${USBREDIR} ]]; then
        (git clone git://anongit.freedesktop.org/spice/usbredir.git -b usbredir-0.4.x)
    if [[ $? != "0" || ! -d ${USBREDIR} ]]; then
        echo "Failed to get usbredir."
        rm -rf ${USBREDIR}
        exit 1
    fi
fi

if [[ ! -e ${MY_LIBS}/libusbredirparser.so ]]; then
          echo "Running autogen.sh"
    (cd ${USBREDIR} && \
        sed '/libusb-/d' -i configure.ac && \
        echo "SUBDIRS = usbredirparser" > Makefile.am &&\
        NOCONFIGURE=1 ./autogen.sh ) && \
    (cd ${USBREDIR} && \
        LDFLAGS=-m64 CFLAGS=-m64 ./configure --prefix=/opt/local && \
        gmake && \
        gmake install)
    if [[ $? != "0" || ! -e ${MY_LIBS}/libusbredirparser.so ]]; then
        echo "Failed to build libusbredirparser."
        exit 1
    fi
fi

QEMUDIR=${PWD}/qemu
if [[ ! -d ${QEMUDIR} ]]; then
	(git clone http://www.shalman.org/spice/qemu.git qemu)
    if [[ $? != "0" || ! -d ${QEMUDIR} ]]; then
        echo "Failed to get qemu."
        rm -rf ${QEMUDIR}
        exit 1
    fi
fi


if [[ ! -e ${PWD}/qemu/x86_64-softmmu/qemu-system-x86_64 ]]; then
    (cd ${QEMUDIR} && \
        CC=gcc bash ../build-dataset.bash)
    if [[ $? != "0" || ! -e ${PWD}/qemu/x86_64-softmmu/qemu-system-x86_64 ]]; then
        echo "Failed to build qemu."
        exit 1
    fi
fi

# NIS - note: a way to set the TCP_NODELAY
# socat TCP4-LISTEN:5930,reuseaddr,fork,setsockopt-int=6:1:1 UNIX-CONNECT:/tmp/spice.sock&"
#echo "Invoke with:"
#echo "./socat TCP4-LISTEN:5930,reuseaddr,fork UNIX-CONNECT:/tmp/spice.sock&"
#echo "./qemu/x86_64-softmmu/qemu-system-x86_64 -m 256 -monitor stdio -machine pc,accel=kvm,kernel_irqchip=on -vga qxl -name "test" -soundhw ac97 -spice sock=/tmp/spice.sock,disable-ticketing"
#echo
#echo "OR"
#echo "copy the content of qemu/zone_dataset/ into a fresh zfs filesystem and use it as the"
#echo "zone_dataset_uuid for a vm you create with vmadm"
#echo "you'll still need socat until vmadm supports spice" 
