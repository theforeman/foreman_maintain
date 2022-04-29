module Checks::Dummy
  class Success < ForemanMaintain::Check
    metadata do
      label :dummy_check_success
      description 'Check that ends up with success'
    end

    def run; end
  end

  class Fail < ForemanMaintain::Check
    metadata do
      label :dummy_check_fail
      description 'Check that ends up with fail'
    end

    def run
      fail! 'this check is always causing failure'
    end
  end

  class Fail2 < ForemanMaintain::Check
    metadata do
      label :dummy_check_fail2
      description 'Check that ends up with fail'
    end

    def run
      fail! 'this check is always causing failure'
    end
  end

  class FailSkipWhitelist < ForemanMaintain::Check
    metadata do
      label :dummy_check_fail_skipwhitelist
      description 'Check that ends up with fail'
      do_not_whitelist
    end

    def run
      fail! 'this check is always causing failure'
    end
  end

  class Warn < ForemanMaintain::Check
    metadata do
      label :dummy_check_warn
      description 'Check that ends up with warning'
    end

    def run
      warn! 'this check is always causing warnings'
    end
  end
end
