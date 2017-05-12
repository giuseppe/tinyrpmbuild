#!/bin/bash

set -xeuo pipefail

TMPDIR=$(mktemp -d)
cd $TMPDIR
function cleanup {
    cd /
    rm -rf $TMPDIR
}
trap cleanup EXIT

mkdir -p $TMPDIR/root/a/b/c
echo hello > $TMPDIR/root/a/b/c/file
echo world > $TMPDIR/root/a/b/c/file2

tinyrpmbuild.py $TMPDIR/root $TMPDIR/rpm.rpm magicpackage
rpm -qlp $TMPDIR/rpm.rpm > list_files
grep "/a/b/c/file" list_files
grep "/a/b/c/file2" list_files
