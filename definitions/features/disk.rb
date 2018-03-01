module Features
  class Disk < ForemanMaintain::Feature
    metadata do
      label :disk
    end

    def usage(dir)
      execute("du -sh #{dir} | cut -f1")
    end
  end
end
