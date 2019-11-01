module Procedures::Packages
  class EnableVersionLocking < ForemanMaintain::Procedure
    metadata do
      description 'Install and configure tools for version locking'
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      package_manager.install_version_locking(:assumeyes => @assumeyes)
    end
  end
end
