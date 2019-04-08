require 'minitest/autorun'
require_relative 'verifier'

class VerifierTest < Minitest::Test
	def test_basic_hash
		v = Verifier.new('sample.txt')
		assert_equal('f896',v.calculate_hash('bill'.unpack('U*')))
	end
end
