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
end
