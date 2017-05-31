module ForemanMaintain
  module Cli
    module Procedure
      class AbstractProcedureCommand < Base
        def execute
          label = underscorize(invocation_path.split.last)
          procedure = procedure(label.to_sym)
          scenario = ForemanMaintain::Scenario.new
          scenario.add_step(procedure.new(params_for_procedure(procedure)))
          run_scenario(scenario)
        end

        # transform clamp options into procedure params
        def options_to_params
          @params ||= self.class.recognised_options.inject({}) do |par, option|
            par[option_sym(option)] = send(option.read_method) if metadata_option?(option)
            par
          end
        end

        def self.params_to_options(params)
          params.values.each do |param|
            param_to_option(param)
          end
        end

        def self.param_to_option(param, custom = {})
          switches = custom.fetch(:switches, option_switches(param))
          opt_type = custom.fetch(:type, option_type(param))
          description = custom.fetch(:description, param.description)
          options = custom.fetch(:options, {})
          # clamp doesnt allow required flags
          options[:required] ||= param.required? unless param.flag?
          options[:multivalued] ||= param.array?
          option(switches, opt_type, description, options)
        end

        def self.option_switches(param)
          ['--' + dashize(param.name.to_s)]
        end

        def self.option_type(param)
          param.flag? ? :flag : param.name.to_s.upcase
        end

        private

        def option_sym(option)
          option.switches.first[2..-1].to_sym
        end

        def metadata_option?(option)
          !option.switches.include?('--help') && !option.switches.include?('--assumeyes')
        end

        def params_for_procedure(procedure)
          all_params = options_to_params
          params = {}
          procedure.params.values.each do |param|
            params[param.name] = all_params[param.name]
          end
          params
        end
      end
    end
  end
end
