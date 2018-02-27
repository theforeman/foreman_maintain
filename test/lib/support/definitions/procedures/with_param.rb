class Procedures::WithParam < ForemanMaintain::Procedure
  metadata do
    param :parameter, 'Parameter'
  end

  def run
    puts @parameter
  end
end
