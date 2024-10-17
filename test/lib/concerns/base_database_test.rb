require 'test_helper'

class FakeDatabase
  include ForemanMaintain::Concerns::BaseDatabase
  include ForemanMaintain::Concerns::SystemHelpers

  attr_reader :configuration

  def initialize(config)
    @configuration = config
  end
end

module ForemanMaintain
  describe Concerns::BaseDatabase do
    describe 'with local db' do
      let(:db) { FakeDatabase.new(config) }
      let(:config) do
        {
          'host' => 'localhost',
          'database' => 'fakedb',
          'username' => 'fakeuser',
          'password' => 'fakepassword',
        }
      end
      let(:expected_env) do
        {
          'PGHOST' => 'localhost',
          'PGPORT' => nil,
          'PGDATABASE' => 'fakedb',
          'PGUSER' => 'fakeuser',
          'PGPASSWORD' => 'fakepassword',
        }
      end

      it 'accepts localhost as local' do
        assert db.local?
      end

      it 'fetches server version' do
        db.expects(:ping!)
        db.expects(:execute!).with(
          'psql --tuples-only --no-align',
          stdin: 'SHOW server_version',
          env: expected_env
        ).returns('13.16')

        assert db.db_version
      end

      it 'drops db' do
        db.expects(:execute!).with("runuser - postgres -c 'dropdb fakedb'").returns('')

        assert db.dropdb
      end

      it 'restores db' do
        file = '/backup/fake.dump'

        db.expects(:execute!).with("runuser - postgres -c 'pg_restore -C -d postgres #{file}'").
          returns('')

        assert db.restore_dump(file, true)
      end

      it 'dumps db' do
        file = '/backup/fake.dump'

        db.expects(:execute!).with(
          "pg_dump -Fc -f /backup/fake.dump",
          env: expected_env
        ).returns('')

        assert db.dump_db(file)
      end

      it 'pings db' do
        db.expects(:execute?).with("psql",
          stdin: "SELECT 1 as ping", env: expected_env).returns(true)

        assert db.ping
      end

      it 'runs db queries' do
        psql_return = <<~PSQL
           test
          ------
             42
          (1 row)
        PSQL

        db.expects(:ping!)
        db.expects(:execute).with("psql",
          stdin: "SELECT 42 as test", env: expected_env).returns(psql_return)

        assert db.psql('SELECT 42 as test')
      end
    end

    describe 'with remote db' do
      let(:db) { FakeDatabase.new(config) }
      let(:config) do
        {
          'host' => 'db.example.com',
          'database' => 'fakedb',
          'username' => 'fakeuser',
          'password' => 'fakepassword',
        }
      end
      let(:expected_env) do
        {
          'PGHOST' => 'db.example.com',
          'PGPORT' => nil,
          'PGDATABASE' => 'fakedb',
          'PGUSER' => 'fakeuser',
          'PGPASSWORD' => 'fakepassword',
        }
      end

      it 'accepts db.example.com as remote' do
        refute db.local?
      end

      it 'drops db' do
        select_statement = <<~SQL
          select string_agg('drop table if exists \"' || tablename || '\" cascade;', '')
          from pg_tables
          where schemaname = 'public';
        SQL
        delete_statement = 'drop table if exists \"faketable\"'
        db.expects(:psql).with(select_statement).returns(delete_statement)
        db.expects(:psql).with(delete_statement).returns('')
        assert db.dropdb
      end

      it 'restores db' do
        file = '/backup/fake.dump'
        restore_cmd = <<~CMD.strip
          pg_restore --no-privileges --clean --disable-triggers -n public -d fakedb #{file}
        CMD

        db.expects(:execute!).with(
          restore_cmd,
          valid_exit_statuses: [0, 1],
          env: expected_env
        ).returns('')

        assert db.restore_dump(file, false)
      end

      it 'dumps remote db' do
        file = '/backup/fake.dump'

        db.expects(:execute!).with(
          "pg_dump -Fc -f /backup/fake.dump",
          env: expected_env
        ).returns('')

        assert db.dump_db(file)
      end
    end
  end
end
