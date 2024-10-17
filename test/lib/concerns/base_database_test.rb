require 'test_helper'

class FakeDatabase
  include ForemanMaintain::Concerns::BaseDatabase
  include ForemanMaintain::Concerns::SystemHelpers
end

module ForemanMaintain
  describe Concerns::BaseDatabase do
    let(:db) { FakeDatabase.new }
    let(:local_config) do
      {
        'host' => 'localhost',
        'database' => 'fakedb',
        'username' => 'fakeuser',
        'password' => 'fakepassword',
      }
    end
    let(:remote_config) do
      {
        'host' => 'db.example.com',
        'database' => 'fakedb',
        'username' => 'fakeuser',
        'password' => 'fakepassword',
      }
    end

    it 'accepts localhost as local' do
      assert db.local?(local_config)
    end

    it 'accepts db.example.com as remote' do
      refute db.local?(remote_config)
    end

    it 'fetches server version' do
      db.expects(:ping).with(local_config).returns(true)
      db.expects(:execute!).with(
        'psql -h localhost  -p 5432 -U fakeuser -d fakedb -c "SHOW server_version" -t -A',
        env: { "PGPASSWORD" => "fakepassword" }
      ).returns('13.16')

      assert db.db_version(local_config)
    end

    it 'drops local db' do
      db.expects(:execute!).with("runuser - postgres -c 'dropdb fakedb'").returns('')

      assert db.dropdb(local_config)
    end

    it 'drops remote db' do
      select_statement = <<-SQL
            select string_agg('drop table if exists \"' || tablename || '\" cascade;', '')
            from pg_tables
            where schemaname = 'public';
      SQL
      delete_statement = 'drop table if exists \"faketable\"'
      db.expects(:psql).with(select_statement).returns(delete_statement)
      db.expects(:psql).with(delete_statement).returns('')
      assert db.dropdb(remote_config)
    end

    it 'restores local db' do
      file = '/backup/fake.dump'

      db.expects(:execute!).with("runuser - postgres -c 'pg_restore -C -d postgres #{file}'").
        returns('')

      assert db.restore_dump(file, true, local_config)
    end

    it 'restores remote db' do
      file = '/backup/fake.dump'
      restore_cmd = <<~CMD.strip
        pg_restore -h db.example.com  -p 5432 -U fakeuser --no-privileges --clean --disable-triggers -n public -d fakedb #{file}
      CMD

      db.expects(:execute!).with(
        restore_cmd,
        valid_exit_statuses: [0, 1],
        env: { "PGPASSWORD" => "fakepassword" }
      ).returns('')

      assert db.restore_dump(file, false, remote_config)
    end

    it 'dumps local db' do
      file = '/backup/fake.dump'

      db.expects(:execute!).with(
        "pg_dump -h localhost  -p 5432 -U fakeuser -Fc fakedb > /backup/fake.dump",
        env: { "PGPASSWORD" => "fakepassword" }
      ).returns('')

      assert db.dump_db(file, local_config)
    end

    it 'dumps remote db' do
      file = '/backup/fake.dump'

      db.expects(:execute!).with(
        "pg_dump -h db.example.com  -p 5432 -U fakeuser -Fc fakedb > /backup/fake.dump",
        env: { "PGPASSWORD" => "fakepassword" }
      ).returns('')

      assert db.dump_db(file, remote_config)
    end

    it 'pings db' do
      db.expects(:execute?).with("psql -h localhost  -p 5432 -U fakeuser -d fakedb",
        stdin: "SELECT 1 as ping", env: { "PGPASSWORD" => "fakepassword" }).returns(true)

      assert db.ping(local_config)
    end

    it 'runs db queries' do
      psql_return = <<~PSQL
         test
        ------
           42
        (1 row)
      PSQL

      db.expects(:ping).with(local_config).returns(true)
      db.expects(:execute).with("psql -h localhost  -p 5432 -U fakeuser -d fakedb",
        stdin: "SELECT 42 as test", env: { "PGPASSWORD" => "fakepassword" }).returns(psql_return)

      assert db.psql('SELECT 42 as test', local_config)
    end
  end
end
