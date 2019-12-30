module ForemanMaintain
  module Utils
    module Disk
      class IODevice
        include ForemanMaintain::Concerns::SystemHelpers

        attr_accessor :dir

        def initialize(dir)
          @dir = dir
        end

        def read_speed
          @read_speed ||= convert_kb_to_mb(fio)
        end

        def unit
          @unit ||= 'MB/sec'
        end

        def available_space
          convert_kb_to_mb(execute!("df #{dir}|awk {'print $4'}|tail -1").to_i)
        end

        private

        # In fio command, --direct option bypass the cache page
        def fio
          cmd = "fio --name=job1 --rw=read --size=1g --output-format=json\
                  --directory=#{dir} --direct=1 --unlink=1"
          stdout = execute(cmd)
          output = JSON.parse(stdout)
          @fio ||= output['jobs'].first['read']['bw'].to_i
        end

        def convert_kb_to_mb(val)
          val / 1024
        end
      end
    end
  end
end
