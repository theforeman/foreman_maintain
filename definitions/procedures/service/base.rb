module Procedures
  module Service
    class Base < ForemanMaintain::Procedure
      metadata do
        advanced_run false
      end

      def self.common_params(context)
        context.instance_eval do
          param :only, 'A comma-separated list of services to run', :array => true
          param :exclude, 'A comma-separated list of services to skip', :array => true
          param :include, 'A comma-separated list of services to include', :array => true
        end
      end

      def run_service_action(action, options)
        action_noun = feature(:service).action_noun(action).capitalize
        puts "\n#{action_noun} the following service(s):"
        services = feature(:service).filtered_services(options, action)
        print_services(services)
        with_spinner('') do |spinner|
          feature(:service).handle_services(spinner, action, options)
        end
      end

      def common_options
        { :only => @only, :exclude => @exclude, :include => @include }
      end

      private

      def print_services(services)
        puts services.values.flatten(1).join(', ')
      end
    end
  end
end
