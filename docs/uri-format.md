# Libvirt URI formats

Libvirt uses Uniform Resource Identifiers (URIs) to identify hypervisor connections. Both local and remote hypervisors are addressed by libvirt using URIs. The URI scheme and path defines the hypervisor to connect to, while the host part of the URI determines where it is located.

# Local URIs

Libvirt local URIs have one of the following forms:

```text
driver:///system
driver:///session
driver+unix:///system
driver+unix:///session
```

All other uses of the libvirt URIs are considered remote, and behave as such, even if connecting to localhost.

The following drivers are currently supported:

- `qemu`: For managing qemu and KVM guests
- `xen`: For managing old-style (Xen 3.1 and older) Xen guests
- `xenapi`: For managing new-style Xen guests
- `uml`: For managing UML guests
- `lxc`: For managing Linux Containers
- `vbox`: For managing VirtualBox guests
- `openvz`: For managing OpenVZ containers
- `esx`: For managing VMware ESX guests
- `one`: For managing OpenNebula guests
- `phyp`: For managing Power Hypervisor guests

The following example shows how to connect to a local QEMU hypervisor using a local URI.

```
import sys
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    print("Failed to open connection to qemu:///system", file=sys.stderr)
    exit(1)
conn.close()
```

## Remote URIs

Remote URIs have the general form (`[...]` meaning an optional part):

```text
driver[+transport]://[username@][hostname][:port]/[path][?extra-parameters]
```

- `driver`: The name of the libvirt hypervisor driver to connect to. This is the same as that used in a local URI. Some examples are xen, qemu, lxc, openvz, and test. As a special case, the pseudo driver name remote can be used, which will cause the remote daemon to probe for an active hypervisor and pick one to use. As a general rule if the application knows what hypervisor it wants, it should always specify the explicit driver name and not rely on automatic probing.

- `transport`: The name of one of the data transports described earlier in this section. Possible values include tls, tcp, unix, ssh and ext. If omitted, it will default to tls if a hostname is provided, or unix if no hostname is provided.

- `username`: When using the SSH data transport this allows choice of a username that differs from the client's current login name.

- `hostname`: The fully qualified hostname of the remote machine. If using TLS with x509 certificates, or SASL with the GSSAPI/Keberos plug-in, it is critical that this hostname match the hostname used in the server's x509 certificates / Kerberos principle. Mis-matched hostnames will guarantee authentication failures.

- `port`: Rarely needed, unless SSH or libvirtd has been configured to run on a non-standard TCP port. Defaults to **22** for the SSH data transport, **16509** for the TCP data transport and **16514** for the TLS data transport.

- `path`: The path should be the same path used for the hypervisor driver's local URIs. For Xen, this is always just `/`, while for QEMU this would be `/system`.

- `extra-parameters`: The URI query parameters provide the mean to fine tune some aspects of the remote connection, and are discussed in depth in the next section.

### Example remote access URIs
- Connect to a remote **Xen** hypervisor on host **node.example.com** using **ssh** tunneled data transport and ssh username **root**.

```text
xen+ssh://root@node.example.com/
```

- Connect to a remote **QEMU** hypervisor on host **node.example.com** using **TLS** with x509 certificates.

```text
qemu://node.example.com/system
```

- Connect to a remote **Xen** hypervisor on host **node.example.com** using **TLS**, skipping verification of the server's x509 certificate (NB: this is compromising your security).
```text
xen://node.example.com/?no_verify=2
```

- Connect to the local **QEMU** instances over a non-standard **Unix socket** (the full path to the Unix socket is supplied explicitly in this case).
```text
qemu+unix:///system?socket=/opt/libvirt/run/libvirt/libvirt-sock
```

- Connect to a libvirtd daemon offering unencrypted **TCP/IP** connections on an alternative TCP **port 5000** and use the test driver with default configuration.
```text
test+tcp://node.example.com:5000/default
```

### Extra parameters

Extra parameters can be added to remote URIs as part of the query string (the part following ***?***). Remote URIs understand the extra parameters shown below. Any others are passed unmodified through to the backend.

!!! note "Note:"
    Parameter values must be URI-escaped.

- `name` *(any transport)*: The local hypervisor URI passed to the remote virConnectOpen function. This URI is normally formed by removing transport, hostname, port number, username and extra parameters from the remote URI, but in certain very complex cases it may be necessary to supply the name explicitly.
Example: `name=qemu:///system`

- `command` *(ssh, ext)*: The external command. For ext transport this is required. For ssh the default is ssh. The PATH is searched for the command.
Example: `command=/opt/openssh/bin/ssh`

- `socket` *(unix, ssh)*: The external command. For ext transport this is required. For ssh the default is ssh. The PATH is searched for the command.
Example: `socket=/opt/libvirt/run/libvirt/libvirt-sock`


- `netcat` *(ssh)*: The name of the netcat command on the remote machine. The default is `nc`. For ssh transport, libvirt constructs an ssh command which looks like:
```text
command -p port [-l username] hostname netcat -U socket
```
Where port, username, hostname can be specified as part of the remote URI, and command, netcat and socket come from extra parameters (or sensible defaults).
Example: `netcat=/opt/netcat/bin/nc`

- `no_verify` *(tls)*: Client checks of the server's certificate are disable if a non-zero value is set. Example: `no_verify=1`

!!! note "Note:"
    To disable server checks of the client's certificate or IP address you must change the libvirtd configuration.

- `no_tty` *(ssh)*: If set to a non-zero value, this stops ssh from asking for a password if it cannot log in to the remote machine automatically (For example, when using a ssh-agent). Use this when you don't have access to a terminal - for example in graphical programs which use libvirt.
Example: `no_tty=1`

The following example shows how to connect to a QEMU hypervisor using a remote URI.

```python
import sys
import libvirt

conn = libvirt.open("qemu+tls://host2/system")
if not conn:
    print("Failed to open connection to qemu+tls://host2/system", file=sys.stderr)
    exit(1)
conn.close()
```