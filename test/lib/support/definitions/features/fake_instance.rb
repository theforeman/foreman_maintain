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
end
