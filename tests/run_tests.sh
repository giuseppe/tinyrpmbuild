#!/bin/bash

set -xeuo pipefail

TMPDIR=$(mktemp -d)
cd $TMPDIR
function cleanup {
    cd /
    rm -rf $TMPDIR
}
trap cleanup EXIT

mkdir -p $TMPDIR/root/{etc,a}/b/c
echo hello > $TMPDIR/root/a/b/c/file
echo world > $TMPDIR/root/a/b/c/file2
echo configuration > $TMPDIR/root/etc/a-conf-file

tinyrpmbuild.py $TMPDIR/root $TMPDIR/rpm.rpm magicpackage
rpm -qlp $TMPDIR/rpm.rpm > list_files
grep "/a/b/c/file$" list_files
grep "/a/b/c/file2$" list_files

# rpm returns 1 for some reason, disable the errors for now...
set +xeuo pipefail
rpm -qp --qf '[%{filenames}: %{fileflags}\n]' $TMPDIR/rpm.rpm > rpm_out
set -xeuo pipefail
grep -q "/etc/a-conf-file:.*1" rpm_out

rm -rf $TMPDIR/root
mkdir -p $TMPDIR/root/dir
dd if=/dev/urandom of=$TMPDIR/root/dir/bigfile count=20 bs=1M
tinyrpmbuild.py $TMPDIR/root $TMPDIR/rpm.rpm packagebigfile
rpm2cpio $TMPDIR/rpm.rpm | cpio -iv --to-stdout dir/bigfile > $TMPDIR/bigfileextracted
cmp $TMPDIR/bigfileextracted $TMPDIR/root/dir/bigfile


if test `id -u` != 0; then
    echo "SKIP NON ROOT TESTS"
    exit 0
fi

# Add more files to the rpm root and rebuild
mkdir -p $TMPDIR/root/{etc,a}/b/c
echo hello > $TMPDIR/root/a/b/c/file
echo world > $TMPDIR/root/a/b/c/file2
echo configuration > $TMPDIR/root/etc/a-conf-file

tinyrpmbuild.py $TMPDIR/root $TMPDIR/rpm.rpm installablerpm

# root only tests
cat > $TMPDIR/script.sh  << EOF
rpm -vi /tmp/rpm.rpm
rpm -vV installablerpm
rpm -e installablerpm
EOF

docker run --rm -ti -v $TMPDIR/rpm.rpm:/tmp/rpm.rpm:Z -v $TMPDIR/script.sh:/tmp/script.sh:Z fedora sh /tmp/script.sh
