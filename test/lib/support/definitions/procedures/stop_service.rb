class Procedures::StopService < ForemanMaintain::Procedure
  metadata do
    for_feature(:present_service)
    tags :pre_migrations
    description 'Stop the running service'
  end

  def run
    feature(:present_service).stop
  end
end
