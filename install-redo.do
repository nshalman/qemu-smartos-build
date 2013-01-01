exec >&2
pkgin -y in py27-sqlite3
git clone git://github.com/apenwarr/redo.git $3 && \
cd $3 && \
gsed 's|/usr/bin/python|/usr/bin/env python|' -i install.do && \
gmake PREFIX=/opt/local install
