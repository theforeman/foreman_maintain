module Procedures::Pulpcore
  class RpmDatarepair < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::PulpCommon

    metadata do
      description 'Rename ContentArtifact relative_paths to match `{N-V-R.A.rpm}`'
      for_feature :pulpcore
    end

    def run
      with_spinner('Running pulpcore-manager rpm-datarepair 4073') do
        # Assumption: services are already started
        execute!(pulpcore_manager('rpm-datarepair 4073'))
      end
    end
  end
end
