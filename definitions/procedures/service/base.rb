module Procedures
  module Service
    class Base < ForemanMaintain::Procedure
      metadata do
        advanced_run false
      end

      def self.common_params(context)
        context.instance_eval do
          param :only, 'A comma-separated list of services to include', :array => true
          param :exclude, 'A comma-separated list of services to skip', :array => true
          param :include_unregister, 'Include unregistered services for action',
                :flag => true, :default => false, :hidden => true
        end
      end

      def run_service_action(action, options)
        action_noun = feature(:service).action_noun(action).capitalize
        puts "#{action_noun} the following service(s):\n"
        services = feature(:service).filtered_services(options)
        print_services(services)

        with_spinner('') do |spinner|
          feature(:service).handle_services(spinner, action, options)
        end
      end

      def common_options
        { :only => @only, :exclude => @exclude, :include_unregister => @include_unregister }
      end

      private

      def print_services(services)
        puts services.map(&:to_s).join(', ')
      end
    end
  end
end
