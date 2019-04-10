# frozen_string_literal: true

require 'flamegraph'

class Verifier
  attr_reader :file, :previous_block_num, :previous_hash, :previous_time, :addr_table

  def initialize(file_name)
    @file = File.open(file_name)
    @previous_block_num = '-1'
    @previous_hash = '0'
    @previous_time = '-1.-1'
  end

  def main
    line_num = 0
    @file.each do |line|
      # puts "#{line}"
      blk_num, old_hash, trans, time, block_hash = line.split('|')
      block_arr = (line[0...line.rindex('|')]).unpack('U*')
      new_hash = calculate_hash(block_arr)
      check_block(blk_num, old_hash, trans, time, new_hash, block_hash.chomp, line_num)
      @previous_block_num = blk_num
      @previous_hash = new_hash
      @previous_time = time
      line_num += 1
    end
    puts 'Valid Blockchain'
  end

  def check_block(blk_num, old_hash, _trans, time, new_hash, block_hash, line)
    error_cases(line, 1, blk_num, @previous_block_num) unless blk_num.to_i == (@previous_block_num.to_i + 1)

    error_cases(line, 2, old_hash, @previous_hash) if old_hash != @previous_hash

    error_cases(line, 3, block_hash, new_hash) if new_hash != block_hash

    error_cases(line, 4, time, @previous_time) unless check_time(time)
  end

  def check_time(time)
    seconds, nano = time.split('.')
    old_seconds, old_nano = @previous_time.split('.')
    return true if seconds.to_i > old_seconds.to_i
    nano.to_i > old_nano.to_i
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
    end
    puts 'BLOCKCHAIN INVALID'
    exit 1
  end
end

Flamegraph.generate('verify.html') do
  verify = Verifier.new(ARGV[0])
  verify.main
end