#!/bin/bash

set -xeuo pipefail

SRCDIR=$(dirname $(readlink -f $0))

TMPDIR=$(mktemp -d)
cd $TMPDIR
function cleanup {
    cd /
    rm -rf $TMPDIR
}
trap cleanup EXIT

mkdir -p $TMPDIR/rootfs/{etc,a}/b/c
echo hello > $TMPDIR/rootfs/a/b/c/file
echo world > $TMPDIR/rootfs/a/b/c/file2
echo configuration > $TMPDIR/rootfs/etc/a-conf-file

tinyrpmbuild.py $TMPDIR/rootfs $TMPDIR/rpm.rpm magicpackage
rpm -qlp $TMPDIR/rpm.rpm > list_files
grep "/a/b/c/file$" list_files
grep "/a/b/c/file2$" list_files

# rpm returns 1 for some reason, disable the errors for now...
set +xeuo pipefail
rpm -qp --qf '[%{filenames}: %{fileflags}\n]' $TMPDIR/rpm.rpm > rpm_out
set -xeuo pipefail
grep -q "/etc/a-conf-file:.*1" rpm_out

rm -rf $TMPDIR/rootfs
mkdir -p $TMPDIR/rootfs/dir
dd if=/dev/urandom of=$TMPDIR/rootfs/dir/bigfile count=20 bs=1M
tinyrpmbuild.py $TMPDIR/rootfs $TMPDIR/rpm.rpm packagebigfile
rpm2cpio $TMPDIR/rpm.rpm | cpio -iv --to-stdout dir/bigfile > $TMPDIR/bigfileextracted
cmp $TMPDIR/bigfileextracted $TMPDIR/rootfs/dir/bigfile

if test `id -u` == 0; then
    $SRCDIR/run_root.sh
    exit 0
fi
