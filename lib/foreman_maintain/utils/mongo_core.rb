module ForemanMaintain::Utils
  class MongoCore
    def services
      { 'mongod' => 5 }
    end

    def server_config_files
      ['/etc/mongod.conf']
    end

    def client_command
      'mongo'
    end

    def dump_command
      'mongodump'
    end

    def restore_command
      'mongorestore'
    end
  end

  class MongoCore34 < MongoCore
    def services
      { 'rh-mongodb34-mongod' => 5 }
    end

    def server_config_files
      ['/etc/opt/rh/rh-mongodb34/mongod.conf']
    end

    def client_command
      'scl enable rh-mongodb34 -- mongo'
    end

    def dump_command
      'scl enable rh-mongodb34 -- mongodump'
    end

    def restore_command
      'scl enable rh-mongodb34 -- mongorestore'
    end
  end

  class MongoCoreInstalled < MongoCore
    include ForemanMaintain::Concerns::SystemHelpers

    attr_reader :services, :server_config_files, :client_command, :dump_command

    def initialize
      @services = {}
      @server_config_files = []

      detect_mongo_default
      detect_mongo_34
      raise ForemanMaintain::Error::Fail, 'Mongo client was not found' unless @client_command
    end

    private

    def detect_mongo_34
      if find_package('rh-mongodb34-mongodb-server')
        @services['rh-mongodb34-mongod'] = 5
        @server_config_files << '/etc/opt/rh/rh-mongodb34/mongod.conf'
      end

      if find_package('rh-mongodb34-mongodb')
        @client_command = 'scl enable rh-mongodb34 -- mongo'
        @dump_command = 'scl enable rh-mongodb34 -- mongodump'
      end
    end

    def detect_mongo_default
      if find_package('mongodb-server')
        @services['mongod'] = 5
        @server_config_files << '/etc/mongod.conf'
      end

      if find_package('mongodb')
        @client_command = 'mongo'
        @dump_command = 'mongodump'
      end
    end
  end
end
