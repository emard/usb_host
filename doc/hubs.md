### Hubs

This is a very brief summary of the second half of Chapter 11, "Hubs" of the USB 1.1 specification. For more detail please refer to that chapter.

#### Introduction

To repeat from the USB architecture page:

Hubs are a core part of the USB specification and the only device class that is described in the base specification. In a system controlled by a USB 1.1 host, the hub functionality is relatively simple:

* The hub has one upstream port and a number of downstream ports (often 4).
* Each downstream port is connected to the upstream port via a bi-directional repeater.
* The hub also includes a standard USB device, which is the hub controller.

This is summarised in the below graphic:

<p align="center">
![a](doc/img/hubstruct.png)

The hub controller manages the downstream ports, e.g. switching power on and off, enabling or disabling the port, sending a reset signal, etc. The host controller takes these actions based on commands received from the host.

#### Endpoints

Hubs implement only a single endpoint (other than EP0). This is an inbound interrupt port that typically expects to be polled 4 times per second. It responds with (typically) one byte, which contains a bitfield of ports with a status change. Bit 0 refers to a status change for the hub controller itself.

See section 11.13 of the Spec for more detail.

#### The Hub descriptor

After enumeration the host should retrieve the hub descriptor:

```C
struct {
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bNbrPorts;
  uint16_t wHubCharacteristics;
  uint8_t  bPwrOn2PwrGood;
  uint8_t  bHubContrCurrent;
  uint8_t  DeviceRemovable;
  uint8_t  PortPwrCtrlMask;
};
```
Note that the `wHubCharacteristics` field is not naturally aligned.

Two fields are important to a basic host implementation: `bNbrPorts` and `bPwrOn2PwrGood`. The former field defines the number of downstream ports on the hub, the latter defines the time it takes for power to settle after switching port power on (typically around 50ms).

See section 11.15 of the Spec for more detail.

#### Reading Port status

#### Controlling Port status

#### A minimal hub driver algorithm

Below is C pseudo-code to manage the downstream ports of a hub with a simplistic algorithm:

```C
// Space for downstream port tasks
TASK porttask[MAXPORT];

// Get descriptor
hubd   = do_cmd(GET_DESC, HUB_DESC);
nports = hubd->bNbrPorts;

// Switch on power for each port
for(int i = 1; i <= nports; i++) {
	do_cmd(SET_FEAT, i, POWER);
	porttask[i] = new_task();
}

while(1) {
	for(int i = 1; i <= nports; i++) {
		status = do_cmd(GET_STATUS, i);
		if (*device inserted*) {      // enumerate new device
			do_cmd(SET_FEAT, i, RESET);
			enumerate_new_device(porttask[i]);
		}
		else if (*device removed*) {  // clear hub flags & restart task
			do_cmd(CLR_FEAT, i, POWER);
			end_task(porttask[i]);
			do_cmd(SET_FEAT, i, POWER);
			porttask[i] = new_task();
		}
	}
}
```

For a real, but still very basic implementation, refer to the code in `hub.c`.
