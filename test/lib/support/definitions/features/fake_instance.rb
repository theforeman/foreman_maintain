class Features::FakeInstance < ForemanMaintain::Feature
  metadata do
    label :instance

    confine do
      true
    end
  end

  def downstream
    false
  end

  def product_name
    "FakeyFakeFake"
  end

  def current_version
    '3.14.2'
  end

  def target_version
    '3.15.0'
  end

  def current_major_version
    current_version.to_s[/^\d+\.\d+/]
  end
end
