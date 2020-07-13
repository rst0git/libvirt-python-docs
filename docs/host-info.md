# Host information

There are various **virConnection** methods that can be used to get information about the virtualization host, including the hostname, maximum support guest CPUs, etc.

## getHostname

```python
getHostname(self)
```

This returns a system hostname on which the hypervisor is running (based on the result of the gethostname system call, but possibly expanded to a fully-qualified domain name via getaddrinfo). If we are connected to a remote system, then this returns the hostname of the remote system.
The following code demonstrates the use of **getHostname**:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

host = conn.getHostname()
print("Hostname: " + host)

conn.close()
```

## getMaxVcpus

```python
getMaxVcpus(self, type)
```

This method can be used to obtain the maximum number of virtual CPUs per-guest the underlying virtualization technology supports. It takes a virtualization *type* as input (which can be **None**), and if successful, returns the number of virtual CPUs supported. If an error occurred, -1 is returned instead. The following code demonstrates the use of **getMaxVcpus**:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

vcpus = conn.getMaxVcpus(None)
print("Maximum support virtual CPUs: {}".format(vcpus))

conn.close()
```

## getInfo

```python
getInfo(self)
```

 This method can be used to obtain various information about the virtualization host. The method returns a **list** if successful and **None** if an error occurred. The list contains the following members:

- **list[0]:** string indicating the CPU model
- **list[1]:** memory size in megabytes
- **list[2]:** the number of active CPUs
- **list[3]:** expected CPU frequency (mhz)
- **list[4]:** the number of NUMA nodes, 1 for uniform memory access
- **list[5]:** number of CPU sockets per node
- **list[6]:** number of cores per socket
- **list[7]:** number of threads per core

The following code demonstrates the use of **getInfo**:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

nodeinfo = conn.getInfo()

print("Model: {}\n"
      "Memory size: {} MB\n"
      "Number of CPUs: {}\n"
      "MHz of CPUs: {}\n"
      "Number of NUMA nodes: {}\n"
      "Number of CPU sockets: {}\n"
      "Number of CPU cores per socket: {}\n"
      "Number of CPU threads per core: {}".format(
    nodeinfo[0], nodeinfo[1], nodeinfo[2], nodeinfo[3],
    nodeinfo[4], nodeinfo[5], nodeinfo[6], nodeinfo[7]))

conn.close()
```

!!! note "Note:"
    Memory size is reported in MiB instead of KiB.

## getCellsFreeMemory

```python
getCellsFreeMemory(self, startCell, maxCells):
```

The **getCellsFreeMemory** method can be used to obtain the amount of free memory (in kilobytes) in some or all of the NUMA nodes in the system. It takes as input the starting cell and the maximum number of cells to retrieve data from. If successful, a **list** is returned with the amount of free memory in each node. On failure **None** is returned. The following code demonstrates the use of **getCellsFreeMemory**:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

nodeinfo = conn.getInfo()
numnodes = nodeinfo[4]

memlist = conn.getCellsFreeMemory(0, numnodes)
cell = 0
for cellfreemem in memlist:
    print("Node {}: {} bytes free memory".format(cell, cellfreemem))
    cell += 1
conn.close()
```

## getType

```python
getType(self)
```

This method can be used to obtain the type of virtualization in use on this connection. If successful it returns a **string** representing the type of virtualization in use. If an error occurred, **None** will be returned instead.

## getVersion

```python
getVersion(name=None)
```

- If no *name* parameter is passed (or *name* is **None**) then the version of the libvirt library is returned as number. Versions numbers are integers:
```text
1000000 * major + 1000 * minor + release
```
- If a *name* is passed and it refers to a driver linked to the libvirt library, then **getVersion** returns a **tuple** of *(library_version, driver_version)*. The returned name is merely the driver name; for example, both KVM and QEMU guests are serviced by the driver for the `qemu://` URI, so a return of `"QEMU"` does not indicate whether KVM acceleration is present.
- If the *name* passed refers to a non-existent driver, then an `No support for hypervisor` exception is raised.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

ver = conn.getVersion()
print("Version: {}".format(ver))
conn.close()
```

## getLibVersion

```python
getLibVersion(self)
```

This method can be used to obtain the version of the libvirt software in use on the host. If successful it returns a **string** with the version, otherwise it returns **None**.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

ver = conn.getLibVersion()
print("Libvirt Version: {}".format(ver))
conn.close()
```

## getURI

```python
getURI(self)
```

The **getURI** method can be used to obtain the URI for the current connection. While this is typically the same string that was passed into the **open** call, the underlying driver can sometimes canonicalize the string. This method will return the canonical version. If successful, it returns a URI **string**. If an error occurred, **None** will be returned instead. The following code demonstrates the use of getURI:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

uri = conn.getURI()
print("Canonical URI: " + uri)
conn.close()
```

## isEncrypted

```python
isEncrypted(self)
```

This method can be used to find out if a given connection is encrypted. If successful it returns **1** for an encrypted connection and **0** for an unencrypted connection. If an error occurred, **-1** will be returned. The following code demonstrates the use of **isEncrypted**:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

print("Connection is encrypted: {}".format(conn.isEncrypted()))
conn.close()
```

## isSecure

```python
isSecure(self)
```

This method can be used to find out if a given connection is classified as secure. A connection will be classified secure if it is either encrypted or it is running on a channel which is not vulnerable to eavesdropping (like a UNIX domain socket). If successful it returns **1** for a secure connection and **0** for an insecure connection. If an error occurred, **-1** will be returned. The following code demonstrates the use of **isSecure**:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

print("Connection is secure: {}".format(conn.isSecure()))
conn.close()
```

## isAlive

```python
isAlive(self)
```

This method determines if the connection to the hypervisor is still alive. A connection will be classed as alive if it is either local, or running over a channel (TCP or UNIX socket) which is not closed.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

alive = conn.isAlive()
print("Connection is alive = {}".format(alive))
conn.close()
```

## compareCPU

```python
compareCPU(self, xmlDesc, flags=0)
```

This method compares the given CPU description with the host CPU. This *xmlDesc* argument is the same used in the XML description for domain descriptions.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

xml = """
<cpu mode="custom" match="exact">
    <model fallback="forbid">kvm64</model>
</cpu>"""

ret = conn.compareCPU(xml)

if ret == libvirt.VIR_CPU_COMPARE_ERROR:
    print("CPUs are not the same or ther was error.")
elif ret == libvirt.VIR_CPU_COMPARE_INCOMPATIBLE:
    print("CPUs are incompatible.")
elif ret == libvirt.VIR_CPU_COMPARE_IDENTICAL:
    print("CPUs are identical.")
elif ret == libvirt.VIR_CPU_COMPARE_SUPERSET:
    print("The host CPU is better than the one specified.")
else:
    print("An Unknown return code was emitted.")

conn.close()
```

## getFreeMemory

```python
getFreeMemory(self)
```

This method compares the given CPU description with the host CPU.

Note that most libvirt APIs provide memory sizes in kilobytes, but in this function the returned value is in bytes. Divide by 1024 as necessary.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

mem = conn.getFreeMemory()
print("Free memory on the node (host) is {} bytes".format(mem))
conn.close()
```

## getFreePages

```python
getFreePages(self, pages, startCell, maxCells, flags=0)
```

This method queries the host system for free pages of specified size. The *pages* argument is a **list** of page sizes that caller is interested in (the size unit is kilobytes, so e.g. pass 2048 for 2MB). The *startCell* argument refers to the first NUMA node that info should be collected from. The *maxCells* argument indicates how many consecutive nodes should be queried. The return value is a **list** containing an indicator of whether or not pages of the specified input sizes are available. An exception will be raised if the host system does not support memory pages of the size requested.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pages = [2048]
start = 0
cellcount = 4
buf = conn.getFreePages(pages, start, cellcount)

i = 0
for page in buf:
    print("Page Size: {} Available pages: {}".format(page, pages[i]))
    i += 1

conn.close()
```

## getMemoryParameters

```python
getMemoryParameters(self, flags=0)
```

This method returns all the available memory parameters as strings.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

buf = conn.getMemoryParameters()

for parm in buf:
    print(parm)

conn.close()
```

## getMemoryStats

```python
getMemoryStats(self, cellNum, flags=0)
```
This method extracts node's memory statistics for either a single or all and single node (host). It returns a **list** of strings.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

buf = conn.getMemoryStats(libvirt.VIR_NODE_MEMORY_STATS_ALL_CELLS)
for parm in buf:
    print(parm)

conn.close()
```