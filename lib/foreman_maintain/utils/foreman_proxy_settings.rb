require 'singleton'
module ForemanMaintain
  module Utils
    class ForemanProxySettings
      include Concerns::SystemHelpers
      include Singleton

      attr_reader :foreman_url, :https_port, :http_port,
                  :foreman_ssl_cert, :foreman_ssl_key, :foreman_ssl_ca

      def initialize
        options = read_file_and_load_all_settings
        valid_attr_keys = %w[
          foreman_url https_port http_port foreman_ssl_cert foreman_ssl_key foreman_ssl_ca
        ]
        attrs = options.select { |key, _value| valid_attr_keys.include?(key.to_s) }
        attrs.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end

      def proxy_port
        https_port || http_port
      end

      def ssl_certs_exists?
        return false unless foreman_ssl_cert && foreman_ssl_key && foreman_ssl_ca
        file_exists?(foreman_ssl_cert) &&
          file_exists?(foreman_ssl_key) &&
          file_exists?(foreman_ssl_ca)
      end

      private

      def read_file_and_load_all_settings
        settings_yml_path = ForemanMaintain.config.foreman_proxy_settings_path
        proxy_settings = {}
        if File.exist?(settings_yml_path)
          proxy_settings = YAML.load(File.open(settings_yml_path)) || {}
        else
          logger.info "Foreman-Proxy settings file #{settings_yml_path} not found."
        end
        proxy_settings
      rescue => e
        raise "Couldn't load foreman-proxy settings file. Error: #{e.message} #{e.backtrace}"
      end
    end
  end
end
