module Checks::Puppet
  class VerifyNoEmptyCacertRequests < ForemanMaintain::Check
    metadata do
      label :puppet_check_no_empty_cert_requests
      for_feature :puppet_server
      tags :default
      description 'Check to verify no empty CA cert requests exist'
    end

    def run
      cacert_requests_directory = feature(:puppet_server).cacert_requests_directory
      if feature(:puppet_server).cacert_requests_dir_exists?
        files = feature(:puppet_server).find_empty_cacert_request_files
        assert(
          files.empty?,
          "Found #{files.length} empty file(s) under #{cacert_requests_directory}",
          :next_steps => Procedures::Puppet::DeleteEmptyCaCertRequestFiles.new
        )
      else
        skip "#{cacert_requests_directory} directory not found"
      end
    end
  end
end
