require 'procedures/service/base'

module Procedures::Service
  class List < Base
    metadata do
      description 'List applicable services'
      Base.common_params(self)
    end

    def run
      services = feature(:service).filtered_services(common_options)
      unit_files = unit_files_list(services)
      puts unit_files + "\n"
      puts 'All services listed'
    end

    def unit_files_list(services)
      if systemd_installed?
        execute("systemctl list-unit-files --type=service | \
                 grep '#{build_regex_for_services(services)}'")
      else
        regex = services.map { |service| "^#{service.name} " }.join('\|')
        execute("chkconfig --list 2>&1 | grep '#{regex}'")
      end
    end

    def build_regex_for_services(services)
      services.map do |service|
        if service.respond_to?(:instance_parent_unit) && service.instance_parent_unit
          "^#{service.instance_parent_unit}.service"
        else
          "^#{service.name}.service"
        end
      end.join('\|')
    end
  end
end
