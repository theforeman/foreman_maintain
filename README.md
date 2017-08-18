# Foreman Maintenance [![Build Status](https://travis-ci.org/theforeman/foreman_maintain.svg?branch=master)](https://travis-ci.org/theforeman/foreman_maintain)

`foreman_maintain` aims to provide various features that helps keeping the
Foreman/Satellite up and running. It supports multiple versions and subparts
of the Foreman infrastructure, including server or smart proxy and is smart
enough to provide the right tools for the specific version.

## Usage

```
Subcommands:
    health                        Health related commands
      list                          List the checks based on criteria
      list-tags                     List the tags to use for filtering checks
      check                         Run the health checks against the system
        --label label               Run only a specific check
        --tags tags                 Limit only for specific set of tags

    upgrade                       Upgrade related commands
      list-versions                 List versions this system is upgradable to
      check --target-version TARGET_VERSION   Run pre-upgrade checks for upgradeing to specified version
      run --target-version TARGET_VERSION     Run the full upgrade
          [--phase=phase TARGET_VERSION]      Run just a specific phase of the upgrade
```

### Upgrades

Foreman-maintain implements upgrade tooling that helps the administrator to go
through the upgrade process.

Foreman-maintain scans the system to know, what version are available
to upgrade to for the particular system. To see what versions are available
for upgrade, run:

```
foreman-maintain upgrade list-versions
```

To perform just the pre-upgrade checks for the system, run:

```
foreman-maintain upgrade check --target-version TARGET_VERSION
```

The upgrade tooling is able to handle the full end-to-end upgrade via:

```
foreman-maintain upgrade run --target-version TARGET_VERSION
```

The upgrade is split into several phases with different level of impact the run
of the system:

  * **pre-upgrade check** - this phase performs the checks to ensure that the system is
    in ready state before the upgrade. The system should still be operational
    at the current version, while this phase runs.

  * **pre-migrations** - these steps perform changes on the system before
    the actual upgrade stars. An example is disabling access to the system from
    external sources, a.k.a. maintenance mode or disabling sync plans during the run.

    After this phase ends, the system is still running the old version, and it's possible
    to revert the changes by running the post-migrations steps.

  * **migrations** - this phase performs the actual migrations, starting with
    configuring new repositories, updated the packages and running the installer.

    At the end of this phase, the system should be fully migrated to the new version.
    However, the system is not fully operational yet, as the post-migrations steps
    need to revert the pre-migrations steps.

  * **post-migrations** - these steps revert the changes made in pre-migrations phase,
    turning the system into fully-operational again.

  * **post-upgrade checks** - this steps should perform sanity check of the system
    to ensure the system is valid and ready to be used again.


The state of the upgrade is kept between runs, allowing to re-run the `upgrade run`
in case of failure. The tool should start at the appropriate point. For example,
in case the upgrade is already in *migrations* phase, there is no point in running
the *pre-upgrade check* phase. In case the upgrade failed before **migrations**
phase made some modifying changes, the tool tries to rollback to the previous
state of the system.

#### Satellite notes

To use custom organzation/activation key for configuring repositories during
upgrade, set the following environment variables

```
export EXTERNAL_SAT_ORG='Sat6-CI'
export EXTERNAL_SAT_ACTIVATION_KEY='Satellite QA RHEL7'
```

## Implementation

`foreman_maintain` maps the CLI commands into definitions. This allows to keep the set
of the commands the user needs to know immutable from version-specific changes. The mapping
between the CLI commands and definitions is made by defining various metadata.

## Definitions

There are various kinds of definitions possible:

* **Features** - aspects that can be present on the system. It can be
  service (foreman, foreman-proxy), a feature (some Foreman plugin),
  a link to external systems (e.g. registered foreman proxy, compute resource)
  or another aspect that can be subject of health checks and maintenance procedures.
* **Checks** - definitions of health checks to indicate health of the system against the present features
* **Procedures** - steps for performing specific operations on the system
* **Scenarios** - combinations of checks and procedures to achieve some goal

The definitions for this components are present in `definitions` folder.

### Features

Before `foreman_maintain` starts, it takes the set of `features` definition
and determines their pesence by running their `confine` blocks against
the system.

The `confine` block can run an external command to check if the feature
is there, or it can check present of other features.

A feature can define additional methods that can be used across other
definitions.

```ruby
class Features::Foreman < ForemanMaintain::Feature
  metadata do
    label :foreman

    confine do
      check_min_version('foreman', '1.7')
    end
  end

  # helper method that can be used in other definitions like this:
  #
  #   feature(:foreman).running?
  def running?
    execute?('systemctl foreman status')
  end
end
```

The features can inherit from each other, which allows overriding
methods for older versions, when newer version of the feature is present
in the system. This way, we shield the other definitions (checks, procedures,
scenarios) from version-specific nuances.

### Checks

Checks define assertions to determine status of the system.

```ruby
class Checks::ForemanIsRuning < ForemanMaintain::Check
  metadata do
    for_feature :foreman
    description 'check foreman service is running'
    tags :default
  end

  def run
    # we are using methods of a feature.
    # we can define additional steps to be executed as a follow-up
    # of assertion failure
    assert(feature(:foreman).running?
           'There are currently paused tasks in the system'),
           :next_steps => Procedures::ForemanStart.new)
  end
end
```

Similarly as features, also checks (and in fact all definitions) can used
`label`, `description` `confine` and `tags` keyword to describe themselves.

Every definition has a `label` (if not stated explicitly, it's
determined from the class name).

In case some operation take more time, it's possible to enable a spinner
and update the spinner continuously with `with_spinner` method.

```ruby
def run
  with_spinner do |spinner|
    spinner.update 'checking foreman is running'
    if feature(:foreman).running?
      spinner.update 'foreman is not started, starting'
      feature(:foreman).start
    else
      spinner.update 'foreman is started, restarting'
    end
  end
end
```

### Procedures

Procedure defines some operation that can be performed against the system.
It can be part of a scenario or be linked from a check as a remediation step.

```ruby
class Procedures::ForemanStart < ForemanMaintain::Procedure
  metadata do
    for_feature :foreman
    description 'start foreman service'
  end

  def run
    feature(:foreman).start
  end
end
```

### Preparation steps

Some steps can require some additional steps to be performed before we
can proceed. A typical example is installing additional dependencies.
A preparation step is usually a procedure.

```ruby
class Procedures::InstallPackage < ForemanMaintain::Procedure
  metadata do
    # definitions of parameters of the procedure
    param :packages, 'List of packages to install', :array => true
  end

  def run
    install_packages(@packages)
  end

  # if false, the step will be considered as done: it will not be executed
  def necessary?
    @packages.any? { |package| package_version(package).nil? }
  end

  def description
    "Install package(s) #{@packages.join(', ')}"
  end
end

class Checks::DiskIO < ForemanMaintain::Check
  metadata do
    description 'check foreman service is running'
    preparation_steps { Procedures::InstallPackage.new(:packages => %w[hdparm]) }
  end

  def run
    execute!('hdparam ...')
  end
end
```

When running a scenario, all the preparation steps in that scenario
will be collected, and run if necessary (the `necessary?` method
returning `true`). The preparation steps will be run as separate scenario.

### Scenarios

Scenarios represent a composition of various steps (checks and procedures) to
achieve some complex maintenance operation in the system (such as upgrade).


```ruby
class Scenarios::PreUpgradeCheckForeman_1_14 < ForemanMaintain::Scenario
  metadata do
    description 'checks before upgrading to Foreman 1.14'
    confine do
      feature(:upstream)
    end
    tags :pre_upgrade_check
  end

  # Method to be called when composing the steps of the scenario
  def compose
    # we can search for the checks by metadata
    steps.concat(find_checks(:default))
  end
end
```

### Hammer

In some cases, it's useful to be able to use the hammer as part of check/fix procedures.
The easiest way to achieve this is to include `ForemanMaintain::Concerns::Hammer` module:

```ruby
include ForemanMaintain::Concerns::Hammer

def run
  hammer('task resume')
end
```

We expect the credentials for the hammer commands to to be stored inside the hammer settings:

```
# ~/.hammer/cli.modules.d/foreman.yml
:foreman:
  :username: 'admin'
  :password: 'changeme'
```

## Implementation components

In order to process the definitions, there are other components present in the `lib` directory.

* **Detector** - searches the checks/procedures/scenarios based on metadata & available features
* **Runner** - executes the scenario
* **Reporter** - reports the results of the run. It's possible to define
  multiple reporters, based on the current use case (CLI, reporting to monitoring tool)
* **Cli** - Clamp-based command line infrastructure, mapping the definitions
  to user commands.

## Testing

Since a single version of `foreman_maintain` is meant to be used against multiple versions and
components combinations, the testing is a crucial part of the process.

There are multiple kind of tests `foreman_maintain`:

* unit tests for implementation components - can be found in `test/lib`
  * this tests are independent of the real-world definitions and are focused
  on the internal implementation (metadata definitions, features detection)
* unit tests for definitions - can be found in `test/definitions`
  * this tests are focusing on testing of the code in definitions directory.
  There is an infrastructure to simulate various combinations of features without
  needing for actually having them present for development
* bats test - TBD
  * to achieve stability, we also want to include bats tests as part of the infrastructure,
  perhaps in combination with ansible playbooks to make the testing against real-world
  instances as easy as possible.

Execute `rake` to run the tests.

## Planned commands:

```
foreman-maintain health [check|fix]
foreman-maintain upgrade [check|run|abort] [foreman_1_14, satellite_6_1, satellite_6_2]
foreman-maintain maintenance-mode [on|off]
foreman-maintain backup [save|restore]
foreman-maintain monitor [display|upload]
foreman-maintain debug [save|upload|tail]
foreman-maintain console
foreman-maintain config
```
