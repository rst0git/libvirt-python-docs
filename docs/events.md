# Event and Timer Handling

The libvirt module provides a complete interface for handling both events and timers. Both event and timer handling are invoked through a function interface as opposed to a class/method interface. This makes it easier to integrate the interface into either a graphical or console program.

## Event Handling

The libvirt module supplies a framework for event handling. While this is most useful for graphical programs, it can also be used for console programs to provide a consistent user interface and control the processing of console events.

Event handling is done through the functions:

### <span>libvirt.**virEventAddHandle**(*fd*, *events*, *cb*, *opaque*)</span>
Register a callback for monitoring file handle events.

- *fd*: file handle to monitor for events
- *events*: bitset of events to watch from **virEventHandleType** constants
- *cb*: callback to invoke when an event occurs
- *opaque*: user data to pass to callback

### <span>libvirt.**virEventRegisterDefaultImpl**()</span>

Registers a default event implementation based on the poll() system call. This is a generic implementation that can be used by any client application which does not have a need to integrate with an external event loop impl.

For proper event handling, it is important that the event implementation is registered before a connection to the Hypervisor is opened.

Once registered, the application has to invoke virEventRunDefaultImpl() in a loop to process events. Failure to do so may result in connections being closed unexpectedly as a result of keepalive timeout. The default event loop fully supports handle and timeout events, but only wakes up on events registered by libvirt API calls such as **virEventAddHandle()** or **virConnectDomainEventRegisterAny()**.

### <span>libvirt.**virEventRegisterImpl**(*addHandle*, *updateHandle*, *removeHandle*, *addTimeout*, *updateTimeout*, *removeTimeout*)</span>

Registers an event implementation, to allow integration with an external event loop. For proper event handling, it is important that the event implementation is registered before a connection to the Hypervisor is opened.

Use of the **virEventAddHandle()** and similar APIs require that the corresponding handler is registered. Use of the **virConnectDomainEventRegisterAny()** and similar APIs requires that the three timeout handlers are registered. Likewise, the three timeout handlers must be registered if the remote server has been configured to send keep-alive messages, or if the client intends to call virConnectSetKeepAlive(), to avoid either side from unexpectedly closing the connection due to inactivity.

If an application does not need to integrate with an existing event loop implementation, then the **virEventRegisterDefaultImpl()** method can be used to setup the generic libvirt implementation.

Once registered, the event loop implementation cannot be changed, and must be run continuously. Note that callbacks may remain registered for a short time even after calling virConnectClose on all open connections, so it is not safe to stop running the event loop immediately after closing the connection.

### <span>libvirt.**virEventRemoveHandle**(*watch*)</span>
Unregister a callback from a file handle.  This function requires that an event loop has previously been registered with **virEventRegisterImpl()** or **virEventRegisterDefaultImpl()**.

### <span>libvirt.**virEventRunDefaultImpl**()</span>
Run one iteration of the event loop. Applications will generally want to have a thread which invokes this method in an infinite loop. Furthermore, it is wise to set up a pipe-to-self handler (via **virEventAddHandle()**) or a timeout (via **virEventAddTimeout()**) before calling this function, as it will block forever if there are no registered events.

### <span>libvirt.**virEventUpdateHandle**(*watch*, *events*)</span>
Change event set for a monitored file handle. This function requires that an event loop has previously been registered with **virEventRegisterImpl()** or **virEventRegisterDefaultImpl()**.

An example program that uses most of these functions follows:

```python
import sys
import os
import logging
import libvirt
import tty
import termios
import atexit

def reset_term():
    termios.tcsetattr(0, termios.TCSADRAIN, attrs)

def error_handler(unused, error):
    # The console stream errors on VM shutdown; we don't care
    if (error[0] == libvirt.VIR_ERR_RPC and
        error[1] == libvirt.VIR_FROM_STREAMS):
        return
    logging.warn(error)

class Console(object):
    def __init__(self, uri, uuid):
        self.uri = uri
        self.uuid = uuid
        self.connection = libvirt.open(uri)
        self.domain = self.connection.lookupByUUIDString(uuid)
        self.state = self.domain.state(0)
        self.connection.domainEventRegister(lifecycle_callback, self)
        self.stream = None
        self.run_console = True
        logging.info("%s initial state %d, reason %d",
                     self.uuid, self.state[0], self.state[1])

def check_console(console):
    if (console.state[0] == libvirt.VIR_DOMAIN_RUNNING or
        console.state[0] == libvirt.VIR_DOMAIN_PAUSED):
        if console.stream is None:
            console.stream = console.connection.newStream(libvirt.VIR_STREAM_NONBLOCK)
            console.domain.openConsole(None, console.stream, 0)
            console.stream.eventAddCallback(libvirt.VIR_STREAM_EVENT_READABLE, stream_callback, console)
    else:
        if console.stream:
            console.stream.eventRemoveCallback()
            console.stream = None

    return console.run_console

def stdin_callback(watch, fd, events, console):
    readbuf = os.read(fd, 1024)
    if readbuf.startswith(""):
        console.run_console = False
        return
    if console.stream:
        console.stream.send(readbuf)

def stream_callback(stream, events, console):
    try:
        received_data = console.stream.recv(1024)
    except:
        return
    os.write(0, received_data)

def lifecycle_callback (connection, domain, event, detail, console):
    console.state = console.domain.state(0)
    logging.info("%s transitioned to state %d, reason %d",
                 console.uuid, console.state[0], console.state[1])

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: {script} URI UUID\n"
              "Example:\n"
              "{script} 'qemu:///system' '32ad945f-7e78-c33a-e96d-39f25e025d81'".format(
                script=sys.argv[0]
            )
        )
        sys.exit(1)

    uri = sys.argv[1]
    uuid = sys.argv[2]

    print("Escape character is ^]")
    logging.basicConfig(filename='msg.log', level=logging.DEBUG)
    logging.info("URI: %s", uri)
    logging.info("UUID: %s", uuid)

    libvirt.virEventRegisterDefaultImpl()
    libvirt.registerErrorHandler(error_handler, None)

    atexit.register(reset_term)
    attrs = termios.tcgetattr(0)
    tty.setraw(0)

    console = Console(uri, uuid)
    console.stdin_watch = libvirt.virEventAddHandle(0, libvirt.VIR_EVENT_HANDLE_READABLE, stdin_callback, console)

    while check_console(console):
        libvirt.virEventRunDefaultImpl()
```