class Checks::QpidQueuesNotClear < ForemanMaintain::Check
  metadata do
    for_feature :qpid
    description 'check for qpid queues'
    tags :pre_upgrade
  end

  def run
    qpid_queues_count = feature(:qpid).count
    assert(qpid_queues_count == 0,
           "There are #{qpid_queues_count} persistent qpid queue(s) present in the system",
           :next_steps => Procedures::QpidQueuesClear.new)
  end
end
