# Live Configuration Change

## Block Device Jobs

Libvirt provides a generic Block Job methods that can be used to initiate and manage operations on disks that belong to a domain. Jobs are started by calling the function associated with the desired operation (eg. **blockPull**). Once started, all block jobs are managed in the same manner. They can be aborted, throttled, and queried. Upon completion, an asynchronous event is issued to indicate the final status.

The following block jobs can be started:

- **blockPull()** starts a block pull operation for the specified disk. This operation is valid only for specially configured disks. **blockPull** will populate a disk image with data from its backing image. Once all data from its backing image has been pulled, the disk no longer depends on a backing image.

A disk can be queried for active block jobs by using **blockJobInfo**. If found, job information is reported in a structure that contains: the job type, bandwidth throttling setting, and progress information.

**virDomainBlockJobAbort()** can be used to cancel the active block job on the specified disk.

Use **blockJobSetSpeed()** to limit the amount of bandwidth that a block job may consume. Bandwidth is specified in units of MB/sec.

```python
import os
import time
import libvirt
import subprocess

domXML = """
<domain type="kvm">
    <name>example</name>
    <memory>131072</memory>
    <vcpu>1</vcpu>
    <os>
        <type arch="x86_64" machine="q35">hvm</type>
    </os>
    <devices>
        <disk type="file" device="disk">
            <driver name="qemu" type="qcow2"/>
            <source file="{disk_img}" />
            <target dev="vda" bus="virtio"/>
        </disk>
    </devices>
</domain>"""

base_img = "/var/lib/libvirt/images/base.qcow2"
rw_layer = "/var/lib/libvirt/images/example.qcow2"

def qemu_img_create(file_path, fmt="qcow2", size=None, backing_file=None)
    cmd = ["qemu-img", "create", "-f", fmt]
    if backing_file:
        cmd.extend(["-b", backing_file])
    cmd.append(file_path)
    if size:
        cmd.append(size)
    subprocess.check_call(cmd)

def build_domain(conn, base_img, top_layer):
    qemu_img_create(base_img, size="100M")
    qemu_img_create(top_layer, backing_file=base_img)
    dom = conn.createXML(domXML.format(disk_img=top_layer), 0)
    return dom

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

dom = build_domain(conn, base_img, rw_layer)
if not dom:
    raise SystemExit("Failed to create domain")

if dom.blockPull(rw_layer, 0, 0) < 0:
    raise SystemExit("Failed to start block pull")

while True:
    info = dom.blockJobInfo(rw_layer, 0)
    if "cur" in info:
        print("BlockPull progress: {} %".format(
              float(100 * info["cur"] / info["end"])))
        time.sleep(1)
    else:
        break

dom.destroy()
os.unlink(base_img)
os.unlink(rw_layer)
conn.close()
```