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
    property_of{
      value = range(lo = 0, hi = 65_536)
    }.check{ |value|
      hashed_value = @checker.hash(value)
      assert (hashed_value = ((value**3000) + (value**value) - (3**value)) * (7**value))
    }
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
    property_of{
      arr = array(10) { range(lo = 0, hi = 256) }
    }.check{ |arr|
      value = @checker.calculate_hash(arr)
      value.split(//).each do |char|
        assert_includes(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9','a', 'b', 'c', 'd', 'e', 'f'], char)
      end
    }
  end

  # Equivalence classes for error_cases(line, err_num, value, expected)
  # err_num = 0 -> was called incorrectly or with a bad file
  # err_num = 1 -> bad block number
  # err_num = 2 -> bad previous hash
  # err_num = 3 -> bad hash of current block
  # err_num = 4 -> bad timestamp
  # err_num = 5 -> bad transaction(s)
  # err_num = 6 -> address is not 6 digits long
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

  # Test for output of error case of address of the wrong length
  def test_err_num_six
	  assert_output("Line 0: Address 12345 is not six digits\nBLOCKCHAIN INVALID\n") { @checker.error_cases(0, 6, '12345', '123456')}
  end
  
  # Tests for do_transactions(x)
  # evaluates all the transactions in a single block 
  # changes balances of each account invlovled in a transaction
  #
  # Test if billcoins added from the system are not subtracted from any account
  def test_sending_from_system
	  property_of {
		  address = range(lo = 0, hi = 999999)
	  }.check { |address|
		address = address.to_s
		while address.length < 6
		  address = '0' + address
		end
          	transaction = "SYSTEM>" + address + "(1)"
		@checker.do_transactions(transaction, 0)
	        @checker.addr_table.each do |key, value|
			refute value.negative?
		end
	  }
  end	  

  # Test if billcoins are properly added and subtracted
  # from addresses involved in transactions
  def test_sending_and_recieving
	  @checker.do_transactions('000000>111111(10):222222>333333(5)', 0)
	  assert @checker.addr_table['000000'] == -10
	  assert @checker.addr_table['111111'] == 10
	  assert @checker.addr_table['222222'] == -5
	  assert @checker.addr_table['333333'] == 5
	  assert @checker.addr_table.length == 4
  end

  # Test if returns false on incorrect address length
  def test_bad_address_length
	  refute @checker.do_transactions('00000>111111(10)', 0)
  end

  # Tests for check_addresses(x)
  # checks if all acounts have positive balances after one block
  # return true if all account balances are zero or greater
  # returns false otherwise
  
  # Valid transactions should return true
  def test_valid_transactions
	  @checker.do_transactions('000000>111111(10):SYSTEM>000000(10)', 0)
	  assert @checker.check_addresses(0)
  end

  # Invalid transactions should return false. Address 000000 has a negative balance.
  def test_invalid_transactions
	  @checker.do_transactions('000000>111111(10)', 0)
	  refute @checker.check_addresses(0)
  end
end
