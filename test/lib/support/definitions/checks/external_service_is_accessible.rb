class Checks::ExternalServiceIsAccessible < ForemanMaintain::Check
  metadata do
    tags :pre_upgrade_check
    description 'external_service_is_accessible'
  end

  def run; end
end
