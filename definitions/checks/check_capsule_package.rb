module Checks
  module Foreman
    class Checks::CheckCapsulePackage < ForemanMaintain::Check
      metadata do
        label :check_capsule_package
        description 'Check if satellite-capsule package installed in satellite server'
        tags :default
        confine do
          feature(:satellite) && feature(:capsule)
        end
      end

      def run
        fail!('There are both satellite and satellite-capsule ' \
              'packages installed in the system.')
      end
    end
  end
end
