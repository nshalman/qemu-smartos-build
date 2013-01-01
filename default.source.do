TARBALL=downloads/${1/.source/}.tar
redo-ifchange $TARBALL
rm -rf $1 $3
mkdir $3
bsdtar -xf $TARBALL -C $3 --strip-components 1 || rm -rf $3
