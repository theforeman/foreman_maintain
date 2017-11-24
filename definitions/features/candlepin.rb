class Features::Candlepin < ForemanMaintain::Feature
  metadata do
    label :candlepin

    confine do
      find_package('candlepin') && feature(:candlepin_database)
    end
  end

  def content_ids_with_null_content_from_cp_env_content
    sql = <<-SQL
      SELECT e.id, ec.contentid
      FROM cp_environment e
      JOIN cp_env_content ec ON e.id = ec.environment_id
      LEFT JOIN cp_content c ON c.id = ec.contentid
      WHERE c.id IS NULL
    SQL
    feature(:candlepin_database).query(sql).map { |r| r['contentid'] }
  end

  def delete_orphaned_records_from_cp_env_content(content_ids)
    quotize_content_ids = content_ids.map { |el| "'#{el}'" }.join(',')
    unless quotize_content_ids.empty?
      feature(:candlepin_database).psql(<<-SQL)
        BEGIN;
         DELETE FROM cp_env_content WHERE contentid IN (#{quotize_content_ids});
        COMMIT;
      SQL
    end
  end
end
