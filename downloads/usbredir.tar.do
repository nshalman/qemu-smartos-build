. ../config.sh
echo ${usbredir} | redo-stamp
curl http://spice-space.org/download/usbredir/${usbredir}.tar.bz2 2>/dev/null
