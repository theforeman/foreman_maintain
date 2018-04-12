module ForemanMaintain::Utils
  module HashTools
    def self.deep_merge!(h, other_h)
      other_h = symbolize_hash(other_h)

      h.merge!(other_h) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge!(old_val, new_val)
        elsif old_val.is_a?(Array) && new_val.is_a?(Array)
          old_val + new_val
        else
          new_val
        end
      end
    end

    def self.symbolize_hash(h)
      h.inject({}) { |sym_hash, (k, v)| sym_hash.update(k.to_sym => v) }
    end
  end
end
