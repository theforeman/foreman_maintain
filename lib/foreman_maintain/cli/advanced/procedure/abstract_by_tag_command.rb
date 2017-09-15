module ForemanMaintain
  module Cli
    module Procedure
      class AbstractByTagCommand < AbstractProcedureCommand
        def self.tag_params_to_options(tag)
          params = params_for_tag(tag)
          params.each_value do |param|
            mapping = param[:procedures]
            instance = param[:instance]
            param_to_option(instance, :description => instance.description + " #{mapping}")
          end
        end

        def self.params_for_tag(tag)
          params = {}
          ForemanMaintain.available_procedures(:tags => tag).each do |procedure|
            procedure.params.each_value do |param|
              unless params.key?(param.name)
                params[param.name] = { :instance => param, :procedures => [] }
              end
              params[param.name][:procedures] += [procedure.label.to_s]
            end
          end
          params
        end

        def execute
          run_scenario(scenario(invocation_path))
          exit runner.exit_code
        end

        private

        def scenario(invocation_path)
          tag = underscorize(invocation_path.split.last).to_sym
          scenario = ForemanMaintain::Scenario.new

          ForemanMaintain.available_procedures(:tags => tag).sort_by(&:label).each do |procedure|
            scenario.add_step(procedure.new(get_params_for(procedure)))
          end

          scenario
        end
      end
    end
  end
end
