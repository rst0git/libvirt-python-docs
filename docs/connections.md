# Connections

 In libvirt, a connection is the underpinning of every action and object in the system. Every entity that wants to interact with libvirt, be it virsh, virt-manager, or a program using the libvirt library, needs to first obtain a connection to the libvirt daemon on the host it is interested in interacting with. A connection describes not only the type of virtualization technology that the agent wants to interact with (qemu, xen, uml, etc), but also describes any authentication methods necessary to connect to that resource.

## Overview

 The very first thing a libvirt agent must do is call the `virInitialize` function, or one of the Python libvirt connection functions to obtain an instance of the `virConnect` class. This instance will be used in subsequent operations. The Python libvirt module provides 3 different functions for connecting to a resource:

```python
import libvirt

conn = libvirt.open(name)
conn = libvirt.openAuth(uri, auth, flags)
conn = libvirt.openReadOnly(name)
```

In all three cases there is a name parameter which in fact refers to the URI of the hypervisor to connect to.

## libvirt.open

The **open** function will attempt to open a connection for full read-write access. It does not have any scope for authentication callbacks to be provided, so it will only succeed for connections where authentication can be done based on the credentials of the application.

```python
import libvirt

conn = libvirt.open("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")
conn.close()
```

The above example opens up a read-write connection to the system `qemu` hypervisor driver, checks to make sure it was successful, and if so closes the connection.

## libvirt.openReadOnly

The **openReadOnly** function will attempt to open a connection for read-only access. Such a connection has a restricted set of method calls that are allowed, and is typically useful for monitoring applications that should not be allowed to make changes. As with **open**, this method has no scope for authentication callbacks, so it relies on credentials.

```python
import libvirt

conn = libvirt.openReadOnly("qemu:///system")
if not conn:
    raise SystemExit("Failed to open connection to qemu:///system")
conn.close()
```

The above example opens up a read-only connection to the system qemu hypervisor driver, checks to make sure it was successful, and if so closes the connection.

## libvirt.openAuth

The **openAuth** function is the most flexible, and effectively obsoletes the previous two functions. It takes an extra parameter providing a *list* which contains the authentication credentials from the client app. The flags parameter allows the application to request a read-only connection with the `VIR_CONNECT_RO` flag if desired. A simple example that uses **openAuth** with *username* and *password* credentials follows. As with **open**, this method has no scope for authentication callbacks, so it relies on credentials.

```python
import libvirt

SASL_USER = "my-super-user"
SASL_PASS = "my-super-pass"

def request_cred(credentials, user_data):
    for credential in credentials:
        if credential[0] == libvirt.VIR_CRED_AUTHNAME:
            credential[4] = SASL_USER
        elif credential[0] == libvirt.VIR_CRED_PASSPHRASE:
            credential[4] = SASL_PASS
    return 0

auth = [[libvirt.VIR_CRED_AUTHNAME, libvirt.VIR_CRED_PASSPHRASE], request_cred, None]

conn = libvirt.openAuth("qemu+tcp://localhost/system", auth, 0)
if not conn:
    raise SystemExit("Failed to open connection to qemu+tcp://localhost/system")

conn.close()
```

To test the above program, the following configuration must be present:

- **/etc/libvirt/libvirtd.conf**
```
listen_tls = 0
listen_tcp = 1
auth_tcp = "sasl"
```

- **/etc/sasl2/libvirt.conf**
```
mech_list: digest-md5
```

- A virt user has been added to the SASL database.

- **libvirtd** has been started with `--listen`.

Once the above is configured, `openAuth` can utilize the configured username and password and allow read-write access to libvirtd.

## libvirt.close

A connection must be released by calling the `close` method of the **virConnection** class when no longer required. Connections are reference counted objects, so there should be a corresponding call to the close method for each open function call.

Connections are reference counted; the count is explicitly increased by the initial (**open**, **openAuth**, and the like); it is also temporarily increased by other methods that depend on the connection remaining alive. The **open** function call should have a matching **close**, and all other references will be released after the corresponding operation completes.

```python
import libvirt

conn1 = libvirt.open("qemu:///system")
if not conn1:
    raise SystemExit("Failed to open connection to qemu:///system")

conn2 = libvirt.open("qemu:///system")
if not conn2:
    raise SystemExit("Failed to open connection to qemu:///system")

conn1.close()
conn2.close()
```

In Python reference counts can be automatically decreased when an class instance goes out of scope or when the program ends. Also note that every other class instance associated with a connection (**virDomain**, **virNetwork**, etc.) will also hold a reference on the connection.