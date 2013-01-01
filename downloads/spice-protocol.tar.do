. ../config.sh
echo ${spice_proto} | redo-stamp
curl http://spice-space.org/download/releases/${spice_proto}.tar.bz2 2>/dev/null
