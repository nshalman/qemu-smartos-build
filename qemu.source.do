#!/bin/bash -x
exec 1>&2
git clone git://github.com/nshalman/qemu.git -b qemu-kvm-1.1.2-for-illumos $3
