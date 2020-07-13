# Domain Configuration

Domains are defined in libvirt using XML. Everything related only to the domain, such as memory and CPU, is defined in the domain XML. The domain XML format is specified at http://libvirt.org/formatdomain.html. This can be accessed locally in `/usr/share/doc/libvirt-devel-version/` if your system has the *libvirt-devel* package installed.

## Boot Modes

Booting via the BIOS is available for hypervisors supporting full virtualization. In this case the BIOS has a boot order priority (floppy, harddisk, cdrom, network) determining where to obtain/find the boot image.

```xml
 ...
  <os>
    <type>hvm</type>
    <loader readonly="yes" type="rom">/usr/lib/xen/boot/hvmloader</loader>
    <nvram template="/usr/share/OVMF/OVMF_VARS.fd">/var/lib/libvirt/nvram/guest_VARS.fd</nvram>
    <boot dev="hd"/>
    <boot dev="cdrom"/>
    <bootmenu enable="yes" timeout="3000"/>
    <smbios mode="sysinfo"/>
    <bios useserial="yes" rebootTimeout="0"/>
  </os>
  ...
```

## Memory / CPU Resources

CPU and memory resources can be set at the time the domain is created or dynamically while the domain is either active or inactive.

CPU resources are set at domain creation using tags in the XML definition of the domain. The hypervisor defines a limit on the number of virtual CPUs that may not be exceeded either at domain creation or at a later time. This maximum can be dependent on a number of resource and hypervisor limits. An example of the CPU XML specification follows.

```xml
<domain>
  ...
  <vcpu placement="static" cpuset="1-4,^3,6" current="1">2</vcpu>
  ...
</domain>
```

Memory resources are also set at domain creation using tags in the XML definition of the domain. Both the maximum and the current allocation of memory to the domain should be set. An example of the Memory XML specification follows.

```xml
<domain>
  ...
  <maxMemory slots="16" unit="KiB">1524288</maxMemory>
  <memory unit="KiB">524288</memory>
  <currentMemory unit="KiB">524288</currentMemory>
  ...
</domain>
```

After the domain has been created the number of virtual CPUs can be increased via the **setVcpus** or the **setVcpusFlags** methods. The number CPUs may not exceed the hypervisor maximum discussed above.

```python
import sys
import libvirt

domID = 6

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID " + str(domID), file=sys.stderr)
    exit(1)

dom.setVcpus(2)
conn.close()
```

Also after the domain has been created the amount of memory can be changes via the **setMemory** or the **setMemoryFlags** methods. The amount of memory should be expressed in kilobytes.

```python
import sys
import libvirt

domID = 6

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID " + str(domID), file=sys.stderr)
    exit(1)

dom.setMemory(4096) # 4 GigaBytes
conn.close()
```

In addition to the **setMemory** method, the alternative method **setMemoryFlags** is also available.