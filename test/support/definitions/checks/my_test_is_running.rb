class Checks::MyTestIsRunning < ForemanMaintain::Check
  requires_feature :my_test_feature
  tags :basic

  def run
    assert(feature(:my_test_feature).running?,
           'My test feature is not running')
  end
end
