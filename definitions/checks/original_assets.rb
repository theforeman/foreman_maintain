class Checks::OriginalAssets < ForemanMaintain::Check
  metadata do
    description 'Check if only installed assets are present on the system'
    tags :post_upgrade
    for_feature :foreman_server
  end

  ASSETS_DIR = '/var/lib/foreman/public/assets'.freeze

  def run
    custom_assets = []
    product_name = feature(:instance).product_name
    with_spinner('Checking for presence of non-original assets...') do
      custom_assets = package_manager.files_not_owned_by_package(ASSETS_DIR)
      logger.info("Non-original assets detected:\n" + custom_assets.join("\n"))
    end
    remove_files = Procedures::Files::Remove.new(:files => custom_assets, :assumeyes => true)
    assert(custom_assets.empty?,
           "Some assets not owned by #{product_name} were detected on the system.\n" \
             'Possible conflicting versions can affect operation of the Web UI.',
           :next_steps => remove_files)
  end
end
