module ForemanMaintain
  module Cli
    module TransformClampOptions
      def self.included(base)
        base.send(:include, OptionsToParams)
        base.extend(ParamsToOptions)
      end

      module OptionsToParams
        def options_to_params
          @params ||= self.class.recognised_options.inject({}) do |par, option|
            par[option_sym(option)] = send(option.read_method) if metadata_option?(option)
            par
          end
        end

        def get_params_for(definition)
          all_params = options_to_params
          params = {}
          definition.params.values.each do |param|
            params[param.name] = all_params[param.name]
          end
          params
        end

        private

        def option_sym(option)
          option.switches.first[2..-1].to_sym
        end

        def metadata_option?(option)
          !option.switches.include?('--help') && !option.switches.include?('--assumeyes')
        end
      end

      module ParamsToOptions
        def params_to_options(params)
          params.values.each do |param|
            param_to_option(param)
          end
        end

        def param_to_option(param, custom = {})
          switches = custom.fetch(:switches, option_switches(param))
          opt_type = custom.fetch(:type, option_type(param))
          description = custom.fetch(:description, param.description)
          options = custom.fetch(:options, {})

          # clamp doesnt allow required flags
          options[:required] ||= param.required? unless param.flag?
          options[:multivalued] ||= param.array?
          option(switches, opt_type, description, options)
        end

        def option_switches(param)
          ['--' + dashize(param.name.to_s)]
        end

        def option_type(param)
          param.flag? ? :flag : param.name.to_s.upcase
        end
      end
    end
  end
end
