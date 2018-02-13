module Checks::Backup
  class CertsTarExist < ForemanMaintain::Check
    metadata do
      description 'Check if proxy certs_tar exist'
      tags :backup
      for_feature :foreman_proxy
    end

    def run
      unless feature(:foreman_proxy).internal?
        if certs_tar && !File.exist?(certs_tar)
          name = feature(:instance).proxy_product_name
          fail! "#{name} certs tar file is not present on the system" \
                " in path '#{certs_tar}'. \nPlease move the file back to that" \
                ' location or generate a new one on the main server.'
        end
      end
    end

    def certs_tar
      feature(:foreman_proxy).certs_tar
    end
  end
end
