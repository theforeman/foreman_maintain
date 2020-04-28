module Checks
  module Foreman
    class Checks::CheckCapsulePackage < ForemanMaintain::Check
      metadata do
        label :check_capsule_package
        description 'Check if satellite-capsule package installed in satellite server'
        tags :pre_upgrade
        confine do
          feature(:satellite) && feature(:capsule)
        end
      end

      def run
        packages = find_package('satellite-capsule')
        assert(
          !packages,
          'There are both satellite and satellite-capsule' \
          ' packages installed in the system',
          :next_steps => Procedures::Foreman::RemoveCapsulePackage.new
        )
      end
    end
  end
end
