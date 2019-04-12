# frozen_string_literal: true

require 'minitest/autorun'
require 'rantly/minitest_extensions'
require_relative 'blockchain_checker'

class BlockchainCheckerTest < Minitest::Test
  def setup
    @checker = BlockchainChecker.new('./valid_test_chains/sample.txt')
  end

  # Tests for hash(x)
  # should generate a hash of x following the formula
  # ((x**3000) + (x**x) - (3**x)) * (7**x)
  # uses property based testing to test the hash function
  def test_hash
    property_of do
      value = range(lo = 0, hi = 65_536)
    end.check do |value|
      hashed_value = @checker.hash(value)
      assert (hashed_value = ((value**3000) + (value**value) - (3**value)) * (7**value))
    end
  end

  # Tests for calculate_hash(arr)
  # hashes each array element, adds it to a sum, takes the whole sum modulo 65536
  # and returns that value as a hexadecimal string
  # Tests if hashes 'bill' correctly
  def test_hash_bill
    assert_equal('f896', @checker.calculate_hash('bill'.unpack('U*')))
  end

  # Tests if leading zeros are printed
  # The hash of 62 is 119 which when converted is not a full four hex characters
  def test_no_leading_zeros
    assert_equal('77', @checker.calculate_hash([62]))
  end

  # Tests if all returned strings only contain hex characters
  # Uses property based testing to test a lot of strings
  def test_only_hex_characters
    property_of do
      arr = array(10) { range(lo = 0, hi = 256) }
    end.check do |arr|
      value = @checker.calculate_hash(arr)
      value.split(//).each do |char|
        assert_includes(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9','a', 'b', 'c', 'd', 'e', 'f'], char)
      end
    end
  end

  # Equivalence classes for error_cases(line, err_num, value, expected)
  # err_num = 0 -> was called incorrectly or with a bad file
  # err_num = 1 -> bad block number
  # err_num = 2 -> bad previous hash
  # err_num = 3 -> bad hash of current block
  # err_num = 4 -> bad timestamp
  # err_num = 5 -> bad transaction(s)
  #
  # Test for output of error case of bad block number
  def test_err_num_one
	  assert_output("Line 0: Invalid block number 1, should be 0\nBLOCKCHAIN INVALID\n") { @checker.error_cases(0, 1, 1, 0)}
  end
 
  # Test for output of error case of bad previous hash
  def test_err_num_two
	  assert_output("Line 0: Previous hash was 333f, should be 288d\nBLOCKCHAIN INVALID\n") { @checker.error_cases(0, 2, '333f', '288d')}
  end
  
  # Test for output of error case of bad hash of current block
  def test_err_num_three
	  assert_output("Line 0: Current hash is 333f, should be 288d\nBLOCKCHAIN INVALID\n") { @checker.error_cases(0, 3, '333f', '288d')}
  end
  
  # Test for output of error case of bad time stamp
  def test_err_num_four
	  assert_output("Line 0: New timestamp 12345.123 <= previous 12345.126\nBLOCKCHAIN INVALID\n") { @checker.error_cases(0, 4, '12345.123', '12345.126')}
  end

  # Test for output of error case of bad transaction(s)
  def test_err_num_five
	  assert_output("Line 0: Address 123456 has invalid balance of -1\nBLOCKCHAIN INVALID\n") { @checker.error_cases(0, 5, -1, 123456)}
  end
end
