# Foreman Maintenance

`foreman_maintain` aims to provide various features that helps keeping the
Foreman/Satellite up and running. It supports multiple versions and subparts
of the Foreman infrastructure, including server or smart proxy and is smart
enough to provide the right tools for the specific version.

## Planned commands:

```
foreman-maintain health [check|fix] [all|tasks|qpid|certs|…]
foreman-maintain upgrade [check|run|abort] [foreman_1_14, satellite_6_1, satellite_6_2]
foreman-maintain maintenance-mode [on|off]
foreman-maintain backup [save|restore]
foreman-maintain monitor [display|upload]
foreman-maintain debug [save|upload|tail]
foreman-maintain console
foreman-maintain config
```

## TODO

* infrastructure for cli unit tests
* infrastructure for bats tests
* update README with latest documentation
* define pre-upgrade checks for various versions
* define checks and procedures for known issues
* define procedure for turning on/off maintenance mode
* define backup commands
* define monitor commands
* define console commands
* define config commands

## Implementation

The tooling is composed from multiple components:

* **Features Discovery** - to find out what's running on the system
* **Checks** - definitions of health checks to indicate health of the system
* **Procedures** - steps for performing specific operations on the system
* **Scenarios** - combinations of checks and procedures to achieve some goal
* **Detector** - searches the checks/procedures/scenarios based on metadata & available features
* **Runner** - executes the scenario
* **Reporter** - reports the results of the run

This components are linked together by metadata, which makes it easier to extend
the existing maintenance operations by new functionality.

### Features Discovery

In order to provide unified experience across multiple versions and plugin
variations, there is a *features discovery* component at the core of
`foreman_maintain`. It allows to determine what's available on the systems and
provide suitable tools for it.
