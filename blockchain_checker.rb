# frozen_string_literal: true

require 'flamegraph'

# Verifies a given blcokchain
class BlockchainChecker
  attr_reader :file, :previous_block_num, :previous_hash, :previous_time, :addr_table

  def initialize(file_name)
    @file = File.open(file_name)
    @previous_block_num = '-1'
    @previous_hash = '0'
    @previous_time = '-1.-1'
    @addr_table = Hash.new(0)
  end

  def main
    line_num = 0
    @file.each do |line|
      # puts "#{line}"
      blk_num, old_hash, trans, time, block_hash = line.split('|')
      block_arr = (line[0...line.rindex('|')]).unpack('U*')
      new_hash = calculate_hash(block_arr)
      do_transactions(trans)
      check_block(blk_num, old_hash, trans, time, new_hash, block_hash.chomp, line_num)
      @previous_block_num = blk_num
      @previous_hash = new_hash
      @previous_time = time
      line_num += 1
    end
    print_addresses
  end

  def check_block(blk_num, old_hash, _trans, time, new_hash, block_hash, line)
    error_cases(line, 1, blk_num, @previous_block_num.to_i + 1) unless blk_num.to_i == (@previous_block_num.to_i + 1)

    error_cases(line, 2, old_hash, @previous_hash) if old_hash != @previous_hash

    error_cases(line, 3, block_hash, new_hash) if new_hash != block_hash

    error_cases(line, 4, time, @previous_time) unless check_time(time)

    check_addresses(line)
  end

  def check_time(time)
    seconds, nano = time.split('.')
    old_seconds, old_nano = @previous_time.split('.')
    return true if seconds.to_i > old_seconds.to_i

    nano.to_i > old_nano.to_i
  end

  def check_addresses(line)
    @addr_table.each do |key, value|
      error_cases(line, 5, value, key) if value < 0
    end
  end

  def do_transactions(trans)
    trans_table = trans.split(':')
    trans_table.each do |transaction|
      sender, reciever = transaction.split('>')
      amt = reciever[(reciever.rindex('(') + 1)...reciever.rindex(')')].to_i
      reciever = reciever[0...reciever.rindex('(')]
      @addr_table[sender] = @addr_table[sender] - amt if sender != 'SYSTEM'
      @addr_table[reciever] = @addr_table[reciever] + amt
    end
  end

  def calculate_hash(block)
    sum = 0
    block.each do |char|
      sum = (sum + hash(char)) % 65_536
    end
    sum.to_s(16)
  end

  def hash(x)
    ((x**3000) + (x**x) - (3**x)) * (7**x)
  end

  def print_addresses
    @addr_table.sort.map do |key, value|
      puts "#{key}: #{value} billcoins" if value > 0
    end
  end

  def error_cases(line, error_num, value, expected)
    case error_num
    when 0
      puts 'Usage: ruby verifier.rb <name_of_file>/nname_of_file = name of file to verify'
    when 1
      puts "Line #{line}: Invalid block number #{value}, should be #{expected}"
    when 2
      puts "Line #{line}: Previous hash was #{value}, should be #{expected}"
    when 3
      puts "Line #{line}: Current hash is #{value}, should be #{expected}"
    when 4
      puts "Line #{line}: New timestamp #{value} <= previous #{expected}"
    when 5
      puts "Line #{line}: Address #{expected} has invalid balance of #{value}"
    end
    puts 'BLOCKCHAIN INVALID'
    exit 1
  end
end
