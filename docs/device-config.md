# Device configuration

Configuration information for a guest domain can be obtained by using the **XMLDesc** method. This method returns the current description of a domain as an XML data stream. This stream can then be parsed to obtain detailed information about the domain and all the parts that make up the domain.

The flags parameter may contain any number of the following constants:

```python
VIR_DOMAIN_XML_SECURE      = 1
VIR_DOMAIN_XML_INACTIVE    = 2
VIR_DOMAIN_XML_UPDATE_CPU  = 4
VIR_DOMAIN_XML_MIGRATABLE  = 8
```

The following example shows how to obtain some basic information about the domain.

```python
import sys
import libvirt
from xml.dom import minidom

domID = 5

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID " + str(domID), file=sys.stderr)
    exit(1)

raw_xml = dom.XMLDesc()
xml = minidom.parseString(raw_xml)
domainTypes = xml.getElementsByTagName("type")
for domainType in domainTypes:
    print(domainType.getAttribute("machine"))
    print(domainType.getAttribute("arch"))

conn.close()
```

## Emulator

To discover the guest domain's emulator find and display the content of the emulator XML tag.

```python
import sys
import libvirt
from xml.dom import minidom

domID = 5

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID " + str(domID), file=sys.stderr)
    exit(1)

raw_xml = dom.XMLDesc()
xml = minidom.parseString(raw_xml)
domainEmulator = xml.getElementsByTagName("emulator")
print("emulator: " + domainEmulator[0].firstChild.data)

conn.close()
```

The XML configuration for the Emulator is typically as follows:

```xml
<domain type="kvm">
    ...
    <emulator>/usr/libexec/qemu-kvm</emulator>
    ...
</domain>
```

## Disks


```python
import sys
import libvirt
from xml.dom import minidom

domID = 1

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID " + str(domID), file=sys.stderr)
    exit(1)

raw_xml = dom.XMLDesc()
xml = minidom.parseString(raw_xml)

diskTypes = xml.getElementsByTagName("disk")
for diskType in diskTypes:
    print("disk: type=" + diskType.getAttribute("type") +
          " device=" + diskType.getAttribute("device"))
    diskNodes = diskType.childNodes
    for diskNode in diskNodes:
        if diskNode.nodeName[0:1] != "#":
            print("  " + diskNode.nodeName)
            for attr in diskNode.attributes.keys():
                print("    " + diskNode.attributes[attr].name +
                      " = " + diskNode.attributes[attr].value)
conn.close()
```

The XML configuration for disks is typically as follows:

```xml
<domain type="kvm">
    ...
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2" cache="none"/>
      <source file="/var/lib/libvirt/images/RHEL7.1-x86_64-1.img"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x06" function="0x0"/>
    </disk>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <target dev="hdc" bus="ide"/>
      <readonly/>
      <address type="drive" controller="0" bus="1" target="0" unit="0"/>
    </disk>
    ...
</domain>
```

## Networking

```python
import sys
import libvirt
from xml.dom import minidom

domID = 1

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID " + str(domID), file=sys.stderr)
    exit(1)

raw_xml = dom.XMLDesc()
xml = minidom.parseString(raw_xml)

interfaceTypes = xml.getElementsByTagName("interface")
for interfaceType in interfaceTypes:
    print("interface: type=" + interfaceType.getAttribute("type"))
    interfaceNodes = interfaceType.childNodes
    for interfaceNode in interfaceNodes:
        if interfaceNode.nodeName[0:1] != "#":
            print("  " + interfaceNode.nodeName)
            for attr in interfaceNode.attributes.keys():
                print("    " + interfaceNode.attributes[attr].name +
                      " = " + interfaceNode.attributes[attr].value)
conn.close()
```

The XML configuration for network interfaces is typically as follows:

```xml
<domain type="kvm">
    ...
    <interface type="network">
      <mac address="52:54:00:94:f0:a4"/>
      <source network="default"/>
      <model type="virtio"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0"/>
    </interface>
    ...
</domain>
```

## Mouse, Keyboard & Tablets

To discover the guest domain's input devices find and display the input XML tags.

```python
import sys
import libvirt
from xml.dom import minidom

domID = 1

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)

dom = conn.lookupByID(domID)
if not dom:
    print("Failed to find domain ID" + str(domID), file=sys.stderr)
    exit(1)

raw_xml = dom.XMLDesc()
xml = minidom.parseString(raw_xml)
devicesTypes = xml.getElementsByTagName("input")
for inputType in devicesTypes:
    print("input: type=" + inputType.getAttribute("type") +
          " bus=" + inputType.getAttribute("bus"))
    inputNodes = inputType.childNodes
    for inputNode in inputNodes:
        if inputNode.nodeName[0:1] != "#":
            print("  "+inputNode.nodeName)
            for attr in inputNode.attributes.keys():
                print("    " + inputNode.attributes[attr].name +
                      " = " + inputNode.attributes[attr].value)
conn.close()
```

The XML configuration for mouse, keyboard and tablet is typically as follows:

```xml
<domain type="kvm">
    ...
    <input type="tablet" bus="usb"/>
    <input type="mouse" bus="ps2"/>
    ...
</domain>
```

## USB Device Passthrough

The USB device passthrough capability allows a physical USB device from the host machine to be assigned directly to a guest machine. The guest OS drivers can use the device hardware directly without relying on any driver capabilities from the host OS.

!!! warning "Important"
    USB devices are only inherited by the guest domain at boot time. newly activated USB devices can not be inherited from the host after the guest domain has booted.

Some caveats apply when using USB device passthrough. When a USB device is directly assigned to a guest, migration will not be possible, without first hot-unplugging the device from the guest. In addition libvirt does not guarantee that direct device assignment is secure, leaving security policy decisions to the underlying virtualization technology.

## PCI device passthrough

The PCI device passthrough capability allows a physical PCI device from the host machine to be assigned directly to a guest machine.The guest OS drivers can use the device hardware directly without relying on any driver capabilities from the host OS.

Some caveats apply when using PCI device passthrough. When a PCI device is directly assigned to a guest, migration will not be possible, without first hot-unplugging the device from the guest. In addition libvirt does not guarantee that direct device assignment is secure, leaving security policy decisions to the underlying virtualization technology. Secure PCI device passthrough typically requires special hardware capabilities, such the VT-d feature for Intel chipset, or IOMMU for AMD chipsets.

There are two modes in which a PCI device can be attached, `managed` or `unmanaged` mode, although at time of writing only KVM supports `managed` mode attachment. In managed mode, the configured device will be automatically detached from the host OS drivers when the guest is started, and then re-attached when the guest shuts down. In `unmanaged` mode, the device must be explicit detached ahead of booting the guest. The guest will refuse to start if the device is still attached to the host OS. The libvirt "Node Device" APIs provide a means to detach/reattach PCI devices from/to host drivers. Alternatively the host OS may be configured to blacklist the PCI devices used for guest, so that they never get attached to host OS drivers.

In both modes, the virtualization technology will always perform a reset on the device before starting a guest, and after the guest shuts down. This is critical to ensure isolation between host and guest OS. There are a variety of ways in which a PCI device can be reset. Some reset techniques are limited in scope to a single device/function, while others may affect multiple devices at once. In the latter case, it will be necessary to co-assign all affect devices to the same guest, otherwise a reset will be impossible to do safely. The node device APIs can be used to determine whether a device needs to be co-assigned, by manually detaching the device and then attempting to perform the reset operation. If this succeeds, then it will be possible to assign the device to a guest on its own. If it fails, then it will be necessary to co-assign the device will others on the same PCI bus.

A PCI device is attached to a guest using the `hostdevice` element. The `mode` attribute should always be set to `subsystem`, and the `type` attribute to `pci`. The `managed` attribute can be either `yes` or `no` as required by the application. Within the `hostdevice` element there is a `source` element and within that a further `address` element is used to specify the PCI device to be attached. The address element expects attributes for `domain`, `bus`, `slot` and `function`. This is easiest to see with a short example:

```xml
<hostdev mode="subsystem" type="pci" managed="yes">
  <source>
    <address domain="0x0000"
             bus="0x06"
             slot="0x12"
             function="0x5"/>
  </source>
</hostdev>
```