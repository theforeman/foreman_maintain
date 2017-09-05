module Checks::Dummy
  class Success < ForemanMaintain::Check
    metadata do
      label :dummy_check_success
      description 'check that ends up with success'
    end

    def run; end
  end

  class Fail < ForemanMaintain::Check
    metadata do
      label :dummy_check_fail
      description 'check that ends up with fail'
    end

    def run
      fail! 'this check is always causing failure'
    end
  end

  class Fail2 < ForemanMaintain::Check
    metadata do
      label :dummy_check_fail2
      description 'check that ends up with fail'
    end

    def run
      fail! 'this check is always causing failure'
    end
  end

  class Warn < ForemanMaintain::Check
    metadata do
      label :dummy_check_warn
      description 'check that ends up with warning'
    end

    def run
      warn! 'this check is always causing warnings'
    end
  end
end
