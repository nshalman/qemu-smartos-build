exec 2>&1
# need git to get code
pkgin -y in scmgit bsdtar

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

bsdtar -C / -xf onbld.tar.gz
