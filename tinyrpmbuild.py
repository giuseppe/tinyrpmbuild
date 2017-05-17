#!/bin/env python
# Released under the terms of the GPLv2

import sys
import rpmwriter

if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.stderr.write("Usage tinyrpmbuild.py TREE RPM-FILE NAME\n")
        sys.exit(1)
    tree, rpm_file, name = sys.argv[1:4]
    with open(rpm_file, "w") as f, open('/dev/null') as stderr:
        writer = rpmwriter.RpmWriter(f, tree, name, "1", "1", stderr=stderr)
        writer.generate()
