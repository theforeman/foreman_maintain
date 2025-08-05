# frozen_string_literal: true

module Reports
  class Selinux < ForemanMaintain::Report
    metadata do
      description 'Report about SELinux enforcement status'
    end

    def run
      data_field('selinux_enforced') { selinux_enforced? }
    end

    private

    def selinux_enforced?
      # Check if getenforce command exists and SELinux is installed
      return false unless command_present?('getenforce')
      
      # Execute getenforce command and check if SELinux is enforcing
      status = execute('getenforce').strip.downcase
      status == 'enforcing'
    rescue StandardError
      # If any error occurs, assume SELinux is not enforced
      false
    end
  end
end
