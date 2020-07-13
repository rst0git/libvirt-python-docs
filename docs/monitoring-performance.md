# Monitoring Performance

Statistical metrics are available for monitoring the utilization rates of domains, vCPUs, memory, block devices, and network interfaces.

## Domain Block Device Performance

Disk usage statistics are provided by the **blockStats** method:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

dom = conn.lookupByID(6)
if not dom:
    raise SystemExit("Failed to find domain ID 6")

(rd_req, rd_bytes,
 wr_req, wr_bytes,
 err) = dom.blockStats("/var/lib/libvirt/images/linux-0.2.img")

print("Read requests issued: {}\n"
      "Bytes read: {}\n"
      "Write requests issued: {}\n"
      "Bytes written: {}\n"
      "Number of errors: {}\n".format(
    rd_req, rd_bytes, wr_req, wr_bytes, err))

conn.close()
```

The returned tuple contains the number of read (write) requests issued, and the actual number of bytes transferred. A block device is specified by the image file path or the device bus name set by the `devices/disk/target[@dev]` element in the domain XML.

In addition to the **blockStats** method, the alternative method **blockStatsFlags** is also available.

## vCPU Performance

To obtain the individual VCPU statistics use the **getCPUStats** method.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

dom = conn.lookupByID(5)
if not dom:
    raise SystemExit("Failed to find domain ID 5")

cpu_stats = dom.getCPUStats(False)
for (i, cpu) in enumerate(cpu_stats):
   print("CPU {} Time: {}".format(i, cpu["cpu_time"] / 1000000000.))

conn.close()
```

The **getCPUStats** takes one parameter, a boolean. When **False** is used the statistics are reported as an aggregate of all the CPUs. Then True is used then each CPU reports its individual statistics. Either way a **list** is returned. The statistics are reported in nanoseconds. If a host has four CPUs, there will be four entries in the cpu_stats list.

**getCPUStats(True)** aggregates the statistics for all CPUs on the host:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

dom = conn.lookupByID(5)
if not dom:
    raise SystemExit("Failed to find domain ID 5")

stats = dom.getCPUStats(True)
print("cpu_time:    {cpu_time}\n"
      "system_time: {system_time}\n"
      "user_time:   {user_time}".format(**stats[0]))

conn.close()
```

## Memory Statistics

To obtain the amount of memory currently used by the domain you can use the **memoryStats** method.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

dom = conn.lookupByID(5)
if not dom:
    raise SystemExit("Failed to find domain ID 5")

stats = dom.memoryStats()
print("memory used:")
for name in stats:
    print("{} ({})".format(stats[name], name))

conn.close()
```

!!! note "Note:"
    **memoryStats** returns a dictionary object. This object will contain a variable number of entries depending on the hypervisor and guest domain capabilities.

## I/O Statistics

To get the network statistics, you'll need the name of the host interface that the domain is connected to (usually vnetX). To find it, retrieve the domain XML description (libvirt modifies it at the runtime). Then, look for `devices/interface/target[@dev]` element(s):

```python
import libvirt
from xml.etree import ElementTree

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

dom = conn.lookupByID(5)
if not dom:
    raise SystemExit("Failed to find domain ID 5")

tree = ElementTree.fromstring(dom.XMLDesc())
iface = tree.find("devices/interface/target").get("dev")
stats = dom.interfaceStats(iface)
print("read bytes:    {}\n"
      "read packets:  {}\n"
      "read errors:   {}\n"
      "read drops:    {}\n"
      "write bytes:   {}\n"
      "write packets: {}\n"
      "write errors:  {}\n"
      "write drops:   {}\n".format(*stats))

conn.close()
```

The **interfaceStats** method returns the number of bytes (packets) received (transmitted), and the number of reception/transmission errors.