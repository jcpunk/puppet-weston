# weston

Manage weston and remote desktops

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with weston](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with weston](#beginning-with-weston)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Weston itself isn't hard to manage. However, setting up workable remote desktop sessions under systemd can be tricky.

This module offers some classes to make this easier, with the complication that it is very prescriptive and opinionated about how this is done.

## Setup

### Setup Requirements

You will need weston in an available package repo.

### Beginning with weston

To install the weston desktop, just include the `weston` module.

## Usage

### VNC Desktops

To create a VNC session include `weston::vnc_server` and set the following parameters:
```yaml
weston::vnc_server::vnc_sessions:
  userA:
    comment: Sometimes you've gotta write it down
    displaynumber: 1
    ensure: running
    enable: true
    user_can_control_service: true
    extra_users_can_control_service:
      - userB
  userB:
    displaynumber: 5902
```

By default the service starting the VNC session is unmanaged.  You can change the defaults via:

```yaml
weston::vnc_server::default_vnc_service_ensure: running
weston::vnc_server::default_vnc_service_enable: true
```

By default users cannot manage the systemd service for their VNC session.  You can grant them access to run `systemctl stop/start/restart weston-vncserver@${username}` one user at a time.  If you would prefer to do it automatically for all users set:

```yaml
weston::vnc_server::default_user_can_control_service: true
```

## Limitations

This module expect VNC to use ports starting at 5900.

For working with VNC desktops, you'll probably want to setup a `~/.config/weston.ini` with the following options:

```ini
[shell]
locking=false

[vnc]
name=yourvncsessionname
mode=1280x720 # this is 720p
resizeable=true
```

as the VNC session will already be protected by PAM.

## Development

See the linked repo from metadata.json
