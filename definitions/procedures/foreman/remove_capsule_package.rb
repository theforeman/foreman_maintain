module Procedures::Foreman
  class RemoveCapsulePackage < ForemanMaintain::Procedure
    metadata do
      description 'Remove the satellite-capsule package from satellite server'
      confine do
        feature(:satellite) && feature(:capsule)
      end
    end

    def capsule_package
      "satellite-capsule-#{feature(:capsule).current_version.version}"
    end

    def run
      execute!("rpm -e --nodeps '#{capsule_package}'")
    end
  end
end
