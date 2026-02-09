# Changelog

All notable changes to this project will be documented in this file.

## Release 0.6.1

**Bugfixes**
User mode doesn't support PAMName

## Release 0.6.0

**Features**
You can now set the minimum vnc port (default is still 5900)
Now sets up a `systemd --user` service that can be run without needing a central config

NOTE: this changes the "internal api" for how `/usr/libexec/weston-vnc` is called

## Release 0.5.1

**Bugfixes**
Fix path for /usr/libexec/weston-vnc

## Release 0.5.0

**Features**
Add ability to manage directory containing weston.ini automatically

## Release 0.4.1

**Bugfixes**
RHEL8 doesn't support `include`

## Release 0.4.0

**Bugfixes**
org.freedesktop.systemd1.manage-unit-files on RHEL8 doesn't provide unit-name

## Release 0.3.1

**Bugfixes**
Fix polkit rules to include org.freedesktop.systemd1.manage-unit-files

## Release 0.3.0

**Features**
Polkit rules now permit users to enable/disable the service

## Release 0.2.1

**Features**
Add `polkit.Result.NOT_HANDLED` to polkit rules

## Release 0.2.0

**Breaking Changes**

weston::vnc_server::export renamed to weston::vnc_server::export_novnc

## Release 0.1.0

**Features**

**Bugfixes**

**Known Issues**
