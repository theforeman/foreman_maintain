class Procedures::QpidQueuesClear < ForemanMaintain::Procedure
  metadata do
    for_feature :qpid
    description 'clear qpid queues'
  end

  def run
    with_spinner('clear qpid queues') do |spinner|
      feature(:katello_service).make_stop(spinner, :exclude => ['qpidd']) do
        spinner.update 'Clearing qpid queues..'
        total_queues_cleared = feature(:qpid).clear_all
        spinner.update "#{total_queues_cleared.length} queues cleared.\
        These queues are recreated by restarting katello-services."
      end
    end
  end
end
