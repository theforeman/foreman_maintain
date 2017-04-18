# Foreman Maintenance

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
      list-versions                List versions this system is upgradable to
      check TARGET_VERSION         Run pre-upgrade checks for upgradeing to specified version
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
  label :foreman

  confine do
    check_min_version('foreman', '1.7')
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
  for_feature :foreman

  description 'check foreman service is running'

  tags :default

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
  for_feature :foreman

  description 'start foreman service'

  def run
    feature(:foreman).start
  end
end
```

### Scenarios

Scenarios represent a composition of various steps (checks and procedures) to
achieve some complex maintenance operation in the system (such as upgrade).


```ruby
class Scenarios::PreUpgradeCheckForeman_1_14 < ForemanMaintain::Scenario
  description 'checks before upgrading to Foreman 1.14'

  confine do
    feature(:upstream)
  end

  tags :pre_upgrade_check

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
