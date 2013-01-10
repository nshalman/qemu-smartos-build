#!/bin/bash
redo-ifchange config.sh prep celt.source
exec 2>&1
. ./config.sh
cd celt.source
./configure --prefix=${MY_PREFIX} --libdir=${MY_LIBS} && \
gsed '/DIR/{s/ tests//}' -i Makefile && \
gmake && \
gmake install
