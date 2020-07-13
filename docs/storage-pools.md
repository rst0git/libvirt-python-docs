# Storage Pools

Libvirt provides storage management on the physical host through storage pools and volumes. A storage pool is a quantity of storage set aside by an administrator, often a dedicated storage administrator, for use by virtual machines. Storage pools are divided into storage volumes either by the storage administrator or the system administrator, and the volumes are assigned to VMs as block devices.

For example, the storage administrator responsible for an NFS server creates a share to store virtual machines' data. The system administrator defines a pool on the virtualization host with the details of the share (e.g. `nfs.example.com:/path/to/share` should be mounted on `/vm_data`). When the pool is started, libvirt mounts the share on the specified directory, just as if the system administrator logged in and executed `mount nfs.example.com:/path/to/share /vmdata`. If the pool is configured to autostart, libvirt ensures that the NFS share is mounted on the directory specified when libvirt is started.

Once the pool is started, the files in the NFS share are reported as volumes, and the storage volumes' paths may be queried using the libvirt APIs. The volumes' paths can then be copied into the section of a VM's XML definition describing the source storage for the VM's block devices. In the case of NFS, an application using the libvirt methods can create and delete volumes in the pool (files in the NFS share) up to the limit of the size of the pool (the storage capacity of the share). Not all pool types support creating and deleting volumes. Stopping the pool (somewhat unfortunately referred to by virsh and the API as "pool-destroy") undoes the start operation, in this case, unmounting the NFS share. The data on the share is not modified by the destroy operation, despite the name. See man virsh for more details.

A second example is an iSCSI pool. A storage administrator provisions an iSCSI target to present a set of LUNs to the host running the VMs. When libvirt is configured to manage that iSCSI target as a pool, libvirt will ensure that the host logs into the iSCSI target and libvirt can then report the available LUNs as storage volumes. The volumes' paths can be queried and used in VM's XML definitions as in the NFS example. In this case, the LUNs are defined on the iSCSI server, and libvirt cannot create and delete volumes.

Storage pools and volumes are not required for the proper operation of VMs. Pools and volumes provide a way for libvirt to ensure that a particular piece of storage will be available for a VM, but some administrators will prefer to manage their own storage and VMs will operate properly without any pools or volumes defined. On systems that do not use pools, system administrators must ensure the availability of the VMs' storage using whatever tools they prefer, for example, adding the NFS share to the host's fstab so that the share is mounted at boot time.

If at this point the value of pools and volumes over traditional system administration tools is unclear, note that one of the features of libvirt is its remote protocol, so it's possible to manage all aspects of a virtual machine's lifecycle as well as the configuration of the resources required by the VM. These operations can be performed on a remote host entirely within the Python libvirt module. In other words, a management application using libvirt can enable a user to perform all the required tasks for configuring the host for a VM: allocating resources, running the VM, shutting it down and deallocating the resources, without requiring shell access or any other control channel.

 Libvirt supports the following storage pool types:

- Directory backend
- Local filesystem backend
- Network filesystem backend
- Logical backend
- Disk backend
- iSCSI backend
- SCSI backend
- Multipath backend
- RBD (RADOS Block Device) backend
- Sheepdog backend
- Gluster backend
- ZFS backend

## Overview

Storage pools are the containers for storage volumes. A system may have as many storage pools as needed and each storage pool may contain as many storage volumes as necessary.

## Listing pools

A list of storage pool objects can be obtained using the **listAllStoragePools** method of the **virConnect** class.

```python
listAllStoragePools(self, flags=0)
```

The *flags* parameter can be one or more of the following constants:

```python
VIR_CONNECT_LIST_STORAGE_POOLS_INACTIVE      = 1
VIR_CONNECT_LIST_STORAGE_POOLS_ACTIVE        = 2
VIR_CONNECT_LIST_STORAGE_POOLS_PERSISTENT    = 4
VIR_CONNECT_LIST_STORAGE_POOLS_TRANSIENT     = 8
VIR_CONNECT_LIST_STORAGE_POOLS_AUTOSTART     = 16
VIR_CONNECT_LIST_STORAGE_POOLS_NO_AUTOSTART  = 32
VIR_CONNECT_LIST_STORAGE_POOLS_DIR           = 64
VIR_CONNECT_LIST_STORAGE_POOLS_FS            = 128
VIR_CONNECT_LIST_STORAGE_POOLS_NETFS         = 256
VIR_CONNECT_LIST_STORAGE_POOLS_LOGICAL       = 512
VIR_CONNECT_LIST_STORAGE_POOLS_DISK          = 1024
VIR_CONNECT_LIST_STORAGE_POOLS_ISCSI         = 2048
VIR_CONNECT_LIST_STORAGE_POOLS_SCSI          = 4096
VIR_CONNECT_LIST_STORAGE_POOLS_MPATH         = 8192
VIR_CONNECT_LIST_STORAGE_POOLS_RBD           = 16384
VIR_CONNECT_LIST_STORAGE_POOLS_SHEEPDOG      = 32768
VIR_CONNECT_LIST_STORAGE_POOLS_GLUSTER       = 65536
VIR_CONNECT_LIST_STORAGE_POOLS_ZFS           = 131072
VIR_CONNECT_LIST_STORAGE_POOLS_VSTORAGE      = 262144
VIR_CONNECT_LIST_STORAGE_POOLS_ISCSI_DIRECT  = 524288
```

The following example shows how to obtain some basic information about available storage pools:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pools = conn.listAllStoragePools()
if not pools:
    raise SystemExit("Failed to locate any StoragePool objects.")

for pool in pools:
    print("Pool: " + pool.name())

conn.close()
```

## Pool usage

There are a number of methods available in the **virStoragePool** class. The following example program features a number of the methods which describe some attributes of a pool.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pool = conn.storagePoolLookupByName("images")
if not pool:
    raise SystemExit("Failed to locate any StoragePool objects.")

info = pool.info()

print("Pool: " + pool.name())
print("  UUID: " + pool.UUIDString())
print("  Autostart: " + str(pool.autostart()))
print("  Is active: " + str(pool.isActive()))
print("  Is persistent: " + str(pool.isPersistent()))
print("  Num volumes: " + str(pool.numOfVolumes()))
print("  Pool state: " + str(info[0]))
print("  Capacity: " + str(info[1]))
print("  Allocation: " + str(info[2]))
print("  Available: " + str(info[3]))

conn.close()
```

Many of the methods shown in the previous example provide information concerning storage pools that are on remote file systems, disk systems, or types other that local file systems. For instance. if the **autostart** flag is set then when the user connects to the storage pool libvirt will automatically make the storage pool available if it is not on a local file system e.g. an NFS mount. Storage pools on local file systems also need to be started if the **autostart** is not set.

The **isActive** method indicates whether or not the user must activate the storage pool in some way. The **create** method can activate a storage pool.

The **isPersistent** method indicates whether or not a storage pool needs to be activated using **create** method. A value of 1 indicates that the storage pool is persistent and will remain on the file system after it is released.

The *flags* parameter can be one or more of the following constants:

```
VIR_STORAGE_XML_INACTIVE = 1
```

The following example shows how to get the XML description of a storage pool.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pool = conn.storagePoolLookupByName("default")
if not pool:
    raise SystemExit("Failed to locate any StoragePool objects.")

xml = pool.XMLDesc()
print(xml)

conn.close()
```

## Lifecycle control

The following example shows how to create and destroy both a persistent and a non-persistent storage pool. Note that a storage pool can not be destroyed if it is in a active state. By default storage pools are created in a inactive state.

```python
import libvirt
xmlDesc = """
<pool type="dir">
  <name>mypool</name>
  <uuid>8c79f996-cb2a-d24d-9822-ac7547ab2d01</uuid>
  <capacity unit="bytes">4306780815</capacity>
  <allocation unit="bytes">237457858</allocation>
  <available unit="bytes">4069322956</available>
  <source>
  </source>
  <target>
    <path>/home/foo/images</path>
    <permissions>
      <mode>0755</mode>
      <owner>-1</owner>
      <group>-1</group>
    </permissions>
  </target>
</pool>"""

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pool = conn.storagePoolDefineXML(xmlDesc, 0)
if not pool:
    raise SystemExit("Failed to create StoragePool object.")

pool.undefine()

pool = conn.storagePoolCreateXML(xmlDesc, 0)
if not pool:
    raise SystemExit("Failed to create StoragePool object.")

pool.undefine()

conn.close()
```

!!! note "Note:"
    The storage volumes defined in a storage pool will remain on the file system unless the delete method is called. But be careful about leaving storage volumes in place because if they exist on a remote file system or disk then that file system may become unavailable to the guest domain since there will be no mechanism to reactivate the remote file system or disk by the libvirt storage system at a future time.

## Discovering pool sources

The sources for a storage pool's sources can be discovered by examining the pool's XML description. An example program follows that prints out a pools source description attributes.

Currently the flags parameter for the **storagePoolCreateXML** method should always be **0**.

```python
import libvirt
from xml.dom import minidom

poolName = "default"

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

sp = conn.storagePoolLookupByName(poolName)
if not sp:
    raise SystemExit("Failed to find storage pool " + poolName)

raw_xml = sp.XMLDesc()
xml = minidom.parseString(raw_xml)
name = xml.getElementsByTagName("name")
print("pool name: " + poolName)

spTypes = xml.getElementsByTagName("source")
for spType in spTypes:
    for attr_name in ["name", "path", "dir", "type", "username"]:
        attr = spType.getAttribute(attr_name)
        if attr:
            print("  {} = {}".format(attr_name, attr))

conn.close()
```

## Pool configuration

There are a number of methods which can configure aspects of a storage pool. The main method is the **setAutostart** method.

```python
import libvirt

poolName = "default"

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

sp = conn.storagePoolLookupByName(poolName)
if not sp:
    raise SystemExit("Failed to find storage pool " + poolName)

print("Current autostart setting: " + str(sp.autostart()))
if sp.autostart():
    sp.setAutostart(0)
else:
    sp.setAutostart(1)
print("Current autostart setting: " + str(sp.autostart()))

conn.close()
```

## Volume overview

Storage volumes are the basic unit of storage which house a guest domain's storage requirements. All the necessary partitions used to house a guest domain are encapsulated by the storage volume. Storage volumes are in turn contained in storage pools. A storage pool can contain as many storage pools as the underlying disk partition will hold.

## Listing volumes

The following example program demonstrates how to list all the storage volumes contained by the `default` storage pool.

```python
import libvirt
from xml.dom import minidom

poolName = "default"

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

sp = conn.storagePoolLookupByName(poolName)
if not sp:
    raise SystemExit("Failed to find storage pool " + poolName)

stgvols = sp.listVolumes()
print("Storage pool: " + poolName)
for stgvol in stgvols :
    print("  Storage vol: " + stgvol)

conn.close()
```

## Volume information

Information about a storage volume is obtained by using the info method. The following program shows how to list the information about each storage volume in the `default` storage pool.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pool = conn.storagePoolLookupByName("default")
if not pool:
    raise SystemExit("Failed to locate any StoragePool objects.")

stgvols = pool.listVolumes()

print("Pool: " + pool.name())
for stgvolname in stgvols:
    print("  Volume: " + stgvolname)
    stgvol = pool.storageVolLookupByName(stgvolname)
    info = stgvol.info()
    print("    Type: " + str(info[0]))
    print("    Capacity: " + str(info[1]))
    print("    Allocation: " + str(info[2]))

conn.close()
```

## Creating and deleting volumes

Storage volumes are created using the storage pool **createXML** method. The type and attributes of the storage volume are specified in the XML passed to the **createXML** method.

The flags parameter can be one or more of the following constants:

```python
VIR_STORAGE_VOL_CREATE_PREALLOC_METADATA = 1
VIR_STORAGE_VOL_CREATE_REFLINK = 2
```

```python
import libvirt

stgvol_xml = """
<volume>
  <name>sparse.img</name>
  <allocation>0</allocation>
  <capacity unit="G">2</capacity>
  <target>
    <path>/var/lib/libvirt/images/sparse.img</path>
    <permissions>
      <owner>107</owner>
      <group>107</group>
      <mode>0744</mode>
      <label>virt_image_t</label>
    </permissions>
  </target>
</volume>"""

pool = "default"

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pool = conn.storagePoolLookupByName(pool)
if not pool:
    raise SystemExit("Failed to locate any StoragePool objects.")

stgvol = pool.createXML(stgvol_xml, 0)
if not stgvol:
    raise SystemExit("Failed to create a  StorageVol objects.")

# remove the storage volume
# physically remove the storage volume from the underlying disk media
stgvol.wipe()
# logically remove the storage volume from the storage pool
stgvol.delete()

conn.close()
```

## Cloning volumes

Cloning a storage volume is similar to creating a new storage volume, except that an existing storage volume is used for most of the attributes. Only the name and permissions in the XML parameter are used for the new volume, everything else is inherited from the existing volume.

It should be noted that cloning can take a very long time to accomplish, depending on the size of the storage volume being cloned. This is because the clone process copies the data from the source volume to the new target volume.

```python
import libvirt

stgvol_xml = """
<volume>
  <name>sparse.img</name>
  <allocation>0</allocation>
  <capacity unit="G">2</capacity>
  <target>
    <path>/var/lib/libvirt/images/sparse.img</path>
    <permissions>
      <owner>107</owner>
      <group>107</group>
      <mode>0744</mode>
      <label>virt_image_t</label>
    </permissions>
  </target>
</volume>"""

stgvol_xml2 = """
<volume>
  <name>sparse2.img</name>
  <allocation>0</allocation>
  <capacity unit="G">2</capacity>
  <target>
    <path>/var/lib/libvirt/images/sparse.img</path>
    <permissions>
      <owner>107</owner>
      <group>107</group>
      <mode>0744</mode>
      <label>virt_image_t</label>
    </permissions>
  </target>
</volume>"""

pool = "default"

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

pool = conn.storagePoolLookupByName(pool)
if not pool:
    raise SystemExit("Failed to locate any StoragePool objects.")

# create a new storage volume
stgvol = pool.createXML(stgvol_xml, 0)
if not stgvol:
    raise SystemExit("Failed to create a  StorageVol object.")

# now clone the existing storage volume
print("This could take some time...")
stgvol2 = pool.createXMLFrom(stgvol_xml2, stgvol, 0)
if not stgvol2:
    raise SystemExit("Failed to clone a  StorageVol object.")

stgvol2.wipe()
stgvol2.delete()

stgvol.wipe()
stgvol.delete()

conn.close()
```

## Configuring volumes

The following is an XML description for a storage volume.

```xml
<volume>
  <name>sparse.img</name>
  <allocation>0</allocation>
  <capacity unit="G">2</capacity>
  <target>
    <path>/var/lib/libvirt/images/sparse.img</path>
    <permissions>
      <owner>107</owner>
      <group>107</group>
      <mode>0744</mode>
      <label>virt_image_t</label>
    </permissions>
  </target>
</volume>
```