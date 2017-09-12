module Procedures::Dummy
  class Fail < ForemanMaintain::Procedure
    metadata do
      label :dummy_procedure_fail
      tags  :fallacious
      description 'Procedure that ends up with fail'
    end

    def run
      fail! 'this procedure is always causing failure'
    end
  end
end
