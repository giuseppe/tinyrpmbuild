# tinyrpmbuild

A Python library for writing RPM files.  It is not supposed to be a
replacement for rpmbuild or be feature complete.  It implements the
basic parts for writing a root file system to an .rpm file.


## Example

Here is a code example:

```python
    with open("new-package.rpm", "w") as f:
        writer = RpmWriter(f, "/tmp/rootfs", "new-package", "1", "1")
        writer.add_require("emacs", ">= 24.0.0")
        writer.add_conflict("vim", ">= 1.0.0")
        writer.generate()
```
