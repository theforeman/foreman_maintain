class Procedures::PassengerRecycler < ForemanMaintain::Procedure
  metadata do
    description 'Perform Passenger memory recycling'

    confine do
      execute?('which passenger-recycler')
    end
  end

  def run
    passenger_recycler_path = execute('which passenger-recycler')
    execute!(passenger_recycler_path)
  end
end
