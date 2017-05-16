#!/bin/bash

rm -rf $TMPDIR/rootfs
mkdir -p $TMPDIR/rootfs/{etc,a}/b/c
echo hello > $TMPDIR/rootfs/a/b/c/file
echo world > $TMPDIR/rootfs/a/b/c/file2
echo configuration > $TMPDIR/rootfs/etc/a-conf-file

tinyrpmbuild.py $TMPDIR/rootfs $TMPDIR/rpm.rpm installablerpm

# root only tests
cat > $TMPDIR/script.sh  << EOF
rpm -vi /tmp/rpm.rpm
rpm -vV installablerpm
rpm -e installablerpm
EOF

docker run --rm -ti -v $TMPDIR/rpm.rpm:/tmp/rpm.rpm:Z -v $TMPDIR/script.sh:/tmp/script.sh:Z fedora sh /tmp/script.sh
