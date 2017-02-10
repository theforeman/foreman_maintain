# Foreman Maintenance

`foreman_maintain` aims to provide various features that helps keeping the
Foreman/Satellite up and running. It supports multiple versions and subparts
of the Foreman infrastructure, including server or smart proxy and is smart
enough to provide the right tools for the specific version.

The project's ambition is to provide unified tooling around:

* health: checking and fixing
* upgrades: pre-upgrade checks, upgrades, post-upgrade checks
* maintenance-mode: setting on and off
* backup: save and restore
* monitor: display or upload to external systems
* shortcut for other tools: console/config

## Implementation

The tooling is composed from multiple components:

* **Features Discovery** - to find out what's running on the system
* **Checks** - definitions of health checks to indicate health of the system
* **Procedures** - steps for performing specific operations on the system
* **Scenarios** - combinations of checks and procedures to achieve some goal
  (such as upgrade)

This components are linked together by metadata, which makes it easier to extend
the existing maintenance operations by new functionality.

### Features Discovery

In order to provide unified experience across multiple versions and plugin
variations, there is a *features discovery* component at the core of
`foreman_maintain`. It allows to determine what's available on the systems and
provide suitable tools for it.
