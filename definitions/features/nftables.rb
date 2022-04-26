class Features::Nftables < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Firewall::NftablesMaintenanceMode
  metadata do
    label :nftables
    confine do
      find_package('nftables')
    end
  end

  def add_table(options = '')
    options = "#{ip_family} #{table_name}" if options.empty?
    execute!("nft add table #{options}")
  end

  def delete_table(options = '')
    options = "#{ip_family} #{table_name}" if options.empty?
    execute!("nft delete table #{options}")
  end

  def add_chain(options = {})
    family = options.fetch(:family, ip_family)
    table = options.fetch(:table, table_name)
    chain = options.fetch(:chain, chain_name)
    chain_options = options.fetch(:chain_options)
    execute!("nft add chain #{family} #{table} #{chain} #{chain_options}")
  end

  def add_rules(options = {})
    family = options.fetch(:family, ip_family)
    table = options.fetch(:table, table_name)
    chain = options.fetch(:chain, chain_name)
    rules = options.fetch(:rules) # needs validation
    rules.each do |rule|
      execute!("nft add rule #{family} #{table} #{chain} #{rule}")
    end
  end

  def table_exist?(name = table_name)
    execute!('nft list tables').include?(name)
  end

  def table_name
    'FOREMAN_MAINTAIN_TABLE'
  end

  def chain_name
    'FOREMAN_MAINTAIN_CHAIN'
  end

  def ip_family
    'inet'
  end
end
