require 'test_helper'

describe Features::SyncPlans do
  include DefinitionsTestHelper

  subject { Features::SyncPlans.new }

  describe '#validate_sync_plan_ids' do
    it 'retuns an empty list if there are no ids' do
      assume_feature_present(:foreman_database) do |db|
        db.any_instance.expects(:query).never
        _(subject.validate_sync_plan_ids([])).must_equal([])
      end
    end

    it 'returns only the present ids' do
      assume_feature_present(:foreman_database) do |db|
        query = "SELECT id FROM katello_sync_plans WHERE id IN ('1','2','3')"
        result = [{ 'id' => '3' }]
        db.any_instance.stubs(:query).with(query).returns(result)
        _(subject.validate_sync_plan_ids([1, 2, 3])).must_equal([3])
      end
    end
  end
end
