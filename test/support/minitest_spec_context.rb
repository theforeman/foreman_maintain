require 'minitest/spec'

module Minitest
  class Spec
    class << self
      alias_method :context, :describe
    end
  end
end
