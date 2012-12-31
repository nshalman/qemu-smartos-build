redo-ifchange config.sh prep usbredir.source
exec 2>&1
. ./config.sh
cd usbredir.source
sed '/libusb-/d' -i configure.ac && \
echo "SUBDIRS = usbredirparser" > Makefile.am && \
NOCONFIGURE=1 ./autogen.sh && \
./configure --prefix=${MY_PREFIX} && \
gmake && \
gmake install
