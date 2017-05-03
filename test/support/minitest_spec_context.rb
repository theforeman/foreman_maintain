require 'minitest/spec'

module MiniTest
  class Spec
    class << self
      alias context describe
    end
  end
end
