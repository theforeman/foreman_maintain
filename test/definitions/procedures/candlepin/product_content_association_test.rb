require 'test_helper'

describe Procedures::Candlepin::ProductContentAssociation do
  include DefinitionsTestHelper

  subject do
    Procedures::Candlepin::ProductContentAssociation.new
  end

  it 'fixes missing association' do
    product_id = '12345'
    product_name = 'dummy'
    content_id = '67890'
    content_name = 'Missing Repo'
    content_uuid = 'dead'
    assume_feature_present(:candlepin_database) do |db|
      db.any_instance.expects(:query).with(
        "SELECT name, uuid FROM cp2_content WHERE content_id = '#{content_id}'"
      ).once.returns([{
        'name' => content_name,
        'uuid' => content_uuid,
      }])
      db.any_instance.expects(:psql).once.returns("BEGIN
INSERT 0 2
UPDATE 1
COMMIT
")
    end

    subject.expects(:foreman_content_num_by_product).once.returns({ product_id => {
      'cp_id' => product_id, 'name' => product_name, 'count' => 1
    } })
    subject.expects(:cp_content_count_by_product).once.returns({ product_id => {
      'product_id' => product_id, 'uuid' => 'feed', 'name' => product_name, 'count' => 0
    } })
    subject.expects(:cp_product_content_ids).once.with(product_id).returns([].to_set)
    subject.expects(:katello_content_ids).once.with(product_id).returns([content_id].to_set)

    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
    msg = "Process Product #{product_name.inspect}\n"
    msg += "  - repair missing: #{content_name.inspect}\n"
    assert_stdout msg
  end
end
