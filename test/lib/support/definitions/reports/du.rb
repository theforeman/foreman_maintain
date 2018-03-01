module Reports
  class DiskUsage < ForemanMaintain::Report
    metadata do
      label :disk_usage
      description 'Report disk consumption and availability of directories'
    end
  end
end
