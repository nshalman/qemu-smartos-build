#!/bin/bash -x
redo-ifchange config.sh qemu-built || exit 1
exec >&2
set -o xtrace
. ./config.sh

PARENT=$(zfs list -H -o name | grep 'data$')
FILESYSTEM=${PARENT}/zone_dataset
zfs create ${FILESYSTEM}
ZONEDIR=$(zfs list -H -o mountpoint ${FILESYSTEM})
UUID=$(uuid)

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

( cd qemu.source && gmake DESTDIR="${ZONEDIR}/root" install ; ) || exit 1

#
# Now figure out the libs we need to copy...
#
LIBS=$(ldd qemu.source/x86_64-softmmu/qemu-system-x86_64 | grep "=>" | awk '{ print $3 }')

for LIB in $LIBS; do
  ISOPT=$(echo "${LIB}" | egrep -e "^/opt/")
  if test -n "$ISOPT"; then
    echo "Copying ${LIB}"
    rsync -LR ${LIB} ${ZONEDIR}/root/ || exit 1
  fi
done

pwd >&2
cp startvm.zone ${ZONEDIR}/root/ || exit 1
chmod +x ${ZONEDIR}/root/startvm.zone
cp usbredir.cfg ${ZONEDIR}/root/${PREFIX}/etc/qemu/ || exit 1

zfs destroy ${FILESYSTEM}@final
zfs snapshot ${FILESYSTEM}@final
mkdir -p ${UUID}
FILENAME=${UUID}/${QEMU_VERSION}-$VERSION.zfs.bz2
zfs send ${FILESYSTEM}@final | pbzip2 > ${FILENAME}

DATE=$(date +%FT%H:%M:%S.0Z)
SIZE=$(ls -l ${FILENAME}  | awk '{ print $5 }')
SHA=$(sha1sum ${FILENAME} | awk '{ print $1 }')
SPICEVER=$(pkgin ls | grep libspice | sed 's|.*-\([0-9.]*\).*|\1|')

sed "
s|VERSION|$VERSION|;
s|SPICEVER|$SPICEVER|;
s|NAME|${QEMU_VERSION}|;
s|DATE|${DATE}|;
s|UUID|${UUID}|;
s|SIZE|$SIZE|;
s|SHA|${SHA}|;" manifest.json.template > ${UUID}/manifest.json

echo "Dataset has been placed in $(pwd)/${UUID}"
