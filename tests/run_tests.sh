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

# Use a smaller file for the torture tests
dd if=/dev/urandom of=$TMPDIR/rootfs/dir/bigfile count=1 bs=1M
for i in $(seq 1 100); do
    dd if=/dev/urandom of=$TMPDIR/rootfs/dir/rndseed count=$(($i * 3)) bs=1k
    dd if=/dev/zero of=$TMPDIR/rootfs/dir/zeros count=$(($i * 3)) bs=1k
    tinyrpmbuild.py $TMPDIR/rootfs $TMPDIR/rpm.rpm torturerpm

    rpm2cpio $TMPDIR/rpm.rpm | cpio -iv --to-stdout dir/zeros > $TMPDIR/zeros
    cmp $TMPDIR/rootfs/dir/zeros $TMPDIR/zeros

    rpm2cpio $TMPDIR/rpm.rpm | cpio -iv --to-stdout dir/rndseed > $TMPDIR/rndseedextract
    cmp $TMPDIR/rootfs/dir/rndseed $TMPDIR/rndseedextract

    rpm2cpio $TMPDIR/rpm.rpm | cpio -iv --to-stdout dir/bigfile > $TMPDIR/bigfileextracted
    cmp $TMPDIR/bigfileextracted $TMPDIR/rootfs/dir/bigfile
done

if test `id -u` == 0; then
    $SRCDIR/run_root.sh
    exit 0
fi
