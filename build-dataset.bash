#!/bin/bash
#
# Copyright (c) 2011, Joyent Inc., All rights reserved.
#

SMARTDC="/smartdc2"

echo "==> Running configure"

#
# Make sure ctf utilities are in our path
#
KERNEL_SOURCE=$(pwd)/../../illumos
CTFBINDIR=$KERNEL_SOURCE/usr/src/tools/proto/root_i386-nd/opt/onbld/bin/i386
export PATH=$PATH:$CTFBINDIR

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
    --cpu=x86_64

if [[ $? != 0 ]]; then
	echo "Failed to configure, bailing"
	exit 1
fi

#
# Build the /smartdc2 directory structure
#

PARENT=$(zfs list -H -o name | grep 'data$')
UUID=zone_dataset
FILESYSTEM=$PARENT/$UUID
zfs create $FILESYSTEM
ZONEDIR=$(zfs list -H -o mountpoint $FILESYSTEM)

#
# clean the old one
#
rm -fr ${ZONEDIR}

#
# Initial setup
#
mkdir ${ZONEDIR}
chmod 700 ${ZONEDIR}
mkdir ${ZONEDIR}/root

# install all the stuff we need...
echo "==> Make"
gmake DESTDIR="${ZONEDIR}/root" install || exit 1

#
# make the lib dir, if needed
#
if [ ! -d "${ZONEDIR}/root/smartdc2/lib" ]; then
  mkdir ${ZONEDIR}/root/smartdc2/lib
fi

#
# Now figure out the libs we need to copy...
#
LIBS=$(ldd x86_64-softmmu/qemu-system-x86_64 | grep "=>" | awk '{ print $3 }')

for LIB in $LIBS; do
  ISOPT=$(echo "${LIB}" | egrep -e "^/opt/")
  if test -n "$ISOPT"; then
    echo "Copying ${LIB}"
    cp ${LIB} ${ZONEDIR}/root/smartdc2/lib || exit 1
  fi
done

#
# And put in our customizations
#
cat > startvm.zone <<"EOF_startvm.zone"
#!/usr/bin/bash
#
# This is a vm start script that processes the standard arguments from vmadmd
# and translates them to work with the new qemu.
#
export LD_LIBRARY_PATH=/lib/64:/usr/lib/64:/smartdc2/lib

#
# We need to build the list of arguments... we need to inject 
# a "machine" argument, and process the "drive" one to remove
# the "boot=on" bit.
#
ARGV[0]="-machine"
ARGV[1]="pc,accel=kvm,kernel_irqchip=on"
ARGV[2]="-readconfig"
ARGV[3]="/smartdc2/etc/qemu/usbredir.cfg"
argc=4
for ARG in "$@"; do
	echo "ARG=$ARG"
	ARG=${ARG%,boot=on}
	echo "ARG=$ARG"
	ARGV[$argc]="$ARG"
	argc=$((argc + 1))
done

echo "FINAL ARGS: " ${ARGV[@]}

exec /smartdc2/bin/qemu-system-x86_64 "${ARGV[@]}"
EOF_startvm.zone
chmod +x startvm.zone

cat > usbredir.cfg <<"EOF_usbredir.cfg"
# qemu config file
# sets up the usb2 bus and the usbredir devices for spice

[device "ehci"]
  driver = "ich9-usb-ehci1"
  addr = "1d.7"
  multifunction = "on"

[device "uhci-1"]
  driver = "ich9-usb-uhci1"
  addr = "1d.0"
  multifunction = "on"
  masterbus = "ehci.0"
  firstport = "0"

[device "uhci-2"]
  driver = "ich9-usb-uhci2"
  addr = "1d.1"
  multifunction = "on"
  masterbus = "ehci.0"
  firstport = "2"

[device "uhci-3"]
  driver = "ich9-usb-uhci3"
  addr = "1d.2"
  multifunction = "on"
  masterbus = "ehci.0"
  firstport = "4"

[chardev "usbredirchardev1"]
  backend = "spicevmc"
  name = "usbredir"

[chardev "usbredirchardev2"]
  backend = "spicevmc"
  name = "usbredir"

[chardev "usbredirchardev3"]
  backend = "spicevmc"
  name = "usbredir"

[device "usbredirdev1"]
  driver = "usb-redir"
  chardev = "usbredirchardev1"
  bus = "ehci.0"
  debug = "3"

[device "usbredirdev2"]
  driver = "usb-redir"
  chardev = "usbredirchardev2"
  bus = "ehci.0"
  debug = "3"

[device "usbredirdev3"]
  driver = "usb-redir"
  chardev = "usbredirchardev3"
  bus = "ehci.0"
  debug = "3"
EOF_usbredir.cfg

cp startvm.zone ${ZONEDIR}/root/ || exit 1
cp usbredir.cfg ${ZONEDIR}/root/smartdc2/etc/qemu/ || exit 1

zfs destroy $FILESYSTEM@final
zfs snapshot $FILESYSTEM@final
VERSION=$(date -u "+%Y%m%dT%H%M%SZ")
FILENAME=spice-$VERSION.zfs.bz2
zfs send $FILESYSTEM@final | pbzip2 > $FILENAME

echo "ZFS stream is stored in $(pwd)/$FILENAME"

DATE=$(date +%FT%H:%M:%S.0Z)
UUID=$(uuid)
SIZE=$(ls -l $FILENAME  | awk '{ print $5 }')
SHA=$(sha1sum $FILENAME | awk '{ print $1 }')

sed "
s|VERSION|$VERSION|;
s|NAME|spice|;
s|DATE|$DATE|;
s|UUID|$UUID|;
s|SIZE|$SIZE|;
s|SHA|$SHA|;" ../manifest.json.template > $FILENAME.manifest
