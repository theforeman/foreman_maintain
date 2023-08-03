require 'minitest/spec'

module Minitest
  class Spec
    class << self
      alias context describe
    end
  end
end
