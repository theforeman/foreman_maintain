module ForemanMaintain::Utils
  module HashTools
    def self.deep_merge!(hash, other_hash)
      other_hash = symbolize_hash(other_hash)

      hash.merge!(other_hash) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge!(old_val, new_val)
        elsif old_val.is_a?(Array) && new_val.is_a?(Array)
          old_val + new_val
        else
          new_val
        end
      end
    end

    def self.symbolize_hash(hash)
      hash.inject({}) { |sym_hash, (key, value)| sym_hash.update(key.to_sym => value) }
    end
  end
end
