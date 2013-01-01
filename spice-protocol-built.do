redo-ifchange config.sh prep spice-protocol.source
. ./config.sh
cd spice-protocol.source
./configure --prefix=${MY_PREFIX} && \
gmake install
