## Capability Information Methods

The **getCapabilities** method call can be used to obtain information about the capabilities of the virtualization host. If successful, it returns a **string** containing the capabilities XML (described below). If an error occurred, **None** will be returned instead.

The following code demonstrates the use of the **getCapabilities** method:

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")

caps = conn.getCapabilities()  # caps will be a string of XML
print("Capabilities:\n" + caps)

conn.close()
```

The capabilities XML format provides information about the host virtualization technology. In particular, it describes the capabilities of the virtualization host, the virtualization driver, and the kinds of guests that the virtualization technology can launch.

!!! note "Note:"
    The capabilities XML can (and does) vary based on the libvirt driver in use.

An example capabilities XML looks like:

```xml
<capabilities>
 <host>
   <cpu>
     <arch>x86_64</arch>
   </cpu>
   <migration_features>
     <live/>
     <uri_transports>
       <uri_transport>tcp</uri_transport>
     </uri_transports>
   </migration_features>
   <topology>
     <cells num="1">
       <cell id="0">
         <cpus num="2">
           <cpu id="0"/>
           <cpu id="1"/>
         </cpus>
       </cell>
     </cells>
   </topology>
 </host>

 <guest>
   <os_type>hvm</os_type>
   <arch name="i686">
     <wordsize>32</wordsize>
     <emulator>/usr/bin/qemu</emulator>
     <machine>pc</machine>
     <machine>isapc</machine>
     <domain type="qemu">
     </domain>
     <domain type="kvm">
       <emulator>/usr/bin/qemu-kvm</emulator>
     </domain>
   </arch>
   <features>
     <pae/>
     <nonpae/>
     <acpi default="on" toggle="yes"/>
     <apic default="on" toggle="no"/>
   </features>
 </guest>

 <guest>
   <os_type>hvm</os_type>
   <arch name="x86_64">
     <wordsize>64</wordsize>
     <emulator>/usr/bin/qemu-system-x86_64</emulator>
     <machine>pc</machine>
     <machine>isapc</machine>
     <domain type="qemu">
     </domain>
     <domain type="kvm">
       <emulator>/usr/bin/qemu-kvm</emulator>
     </domain>
   </arch>
   <features>
     <acpi default="on" toggle="yes"/>
     <apic default="on" toggle="no"/>
   </features>
 </guest>

</capabilities>
```

(the rest of the discussion will refer back to this XML using XPath notation). In the capabilities XML, there is always the **/host** sub-document, and zero or more **/guest** sub-documents (while zero guest sub-documents are allowed, this means that no guests of this particular driver can be started on this particular host).

- **/host**

Describes the capabilities of the host.

- **/host/uuid**

Shows the UUID of the host. This is derived from the SMBIOS UUID if it is available and valid, or can be overridden in `libvirtd.conf` with a custom value. If neither of the above are properly set, a temporary UUID will be generated each time that libvirtd is restarted.

- **/host/cpu**

Describes the capabilities of the host's CPUs. It is used by libvirt when deciding whether a guest can be properly started on this particular machine, and is also consulted during live migration to determine if the destination machine supplies the necessary flags to continue to run the guest.

- **/host/cpu/arch**

A required XML node that describes the underlying host CPU architecture. As of this writing, all libvirt drivers initialize this from the output of `uname`.

- **/host/cpu/model**

An optional element that describes the CPU model that the host CPUs most closely resemble. The list of CPU models that libvirt currently know about are in the `cpu_map.xml` file.

- **/host/cpu/feature**

Zero or more elements that describe additional CPU features that the host CPUs have that are not covered in **/host/cpu/model**.

- **/host/cpu/features**

An optional sub-document that describes additional cpu features present on the host. As of this writing, it is only used by the xen driver to report on the presence or lack of the svm or vmx flag, and to report on the presence or lack of the pae flag.

- **/host/migration_features**

An optional sub-document that describes the migration features that this driver supports on this host (if any). If this sub-document does not exist, then migration is not supported. As of this writing, the xen, qemu, and esx drivers support migration.

- **/host/migration_features/live**

XML node exists if the driver supports live migration.

- **/host/migration_features/uri_transports**

An optional sub-document that describes alternate migration connection mechanisms. These alternate connection mechanisms can be useful on multi-homed virtualization systems. For instance, the `virsh migrate` command might connect to the source of the migration via 10.0.0.1, and the destination of the migration via 10.0.0.2. However, due to security policy, the source of the migration might only be allowed to talk directly to the destination of the migration via 192.168.0.0/24. In this case, using the alternate migration connection mechanism would allow this migration to succeed. As of this writing, the xen driver supports the alternate migration mechanism "xenmigr", while the qemu driver supports the alternate migration mechanism "tcp". Please see the documentation on migration for more information.

- **/host/topology**

A sub-document that describes the NUMA topology of the host machine; each NUMA node is represented by a **/host/topology/cells/cell**, and describes which CPUs are in that NUMA node. If the host machine is a UMA (non-NUMA) machine, then there will be only one cell and all CPUs will be in this cell. This is very hardware-specific, so will necessarily vary between different machines.

- **/host/secmodel**

An optional sub-document that describes the security model in use on the host. **/host/secmodel/model** shows the name of the security model while **/host/secmodel/doi** shows the Domain Of Interpretation. For more information about security, please see the Security section.

- **/guest**

Each **/guest** sub-document describes a kind of guest that this host driver can start. This description includes the architecture of the guest (i.e. i686) along with the ABI provided to the guest (i.e. hvm, xen, or uml).

- **/guest/os_type**

A required element that describes the type of guest.

<center>

| Driver | Guest Type |
| - | - |
| qemu | Always "hvm" |
| xen | Either "xen" for a paravirtualized guest or "hvm" for a fully virtualized guest |
| uml | Always "uml" |
| lxc | Always "exe" |
| vbox | Always "hvm" |
| openvz | Always "exe" |
| one | Always "hvm" |
| ex | Not supported at this time |

</center>


- **/guest/arch**

The root of an XML sub-document describing various virtual hardware aspects of this guest type. It has a single attribute called "name", which can be used to refer back to this sub-document.

- **/guest/arch/wordsize**

A required element that describes how many bits per word this guest type uses. This is typically 32 or 64.

- **/guest/arch/emulator**

An optional element that describes the default path to the emulator for this guest type. Note that the emulator can be overridden by the **/guest/arch/domain/emulator** element (described below) for guest types that need alternate binaries.

- **/guest/arch/loader**

An optional element that describes the default path to the firmware loader for this guest type. Note that the default loader path can be overridden by the **/guest/arch/domain/loader** element (described below) for guest types that use alternate loaders. At present, this is only used by the xen driver for HVM guests.

- **/guest/arch/machine**

There can be zero or more **/guest/arch/machine** elements that describe the default types of machines that this guest emulator can emulate. These "machines" typically represent the ABI or hardware interface that a guest can be started with. Note that these machine types can be overridden by the **/guest/arch/domain/machine** elements (described below) for virtualization technologies that provide alternate machine types. Typical values for this are "pc", and "isapc", meaning a regular PCI based PC, and an older, ISA based PC, respectively.

- **/guest/arch/domain**

There can be zero or more **/guest/arch/domain** XML sub-trees (although with zero /guest/arch/domain XML sub-trees, no guests of this driver can be started). Each /guest/arch/domain XML sub-tree has optional `<emulator>`, `<loader>`, and `<machine>` elements that override the respective defaults specified above. For any of the elements that are missing, the default values are used.

- **/guest/features**

An optional sub-document describes various additional guest features that can be enabled or disabled, along with their default state and whether they can be toggled on or off.