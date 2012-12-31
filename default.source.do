redo-ifchange config.sh
. ./config.sh
TARBALL=downloads/${1/.source/}.tar
redo-ifchange $TARBALL
mkdir $3
bsdtar -xf $TARBALL -C $3 --strip-components 1 || rm -rf $3
