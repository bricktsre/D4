require 'flamegraph'

class Verifier
  attr_reader :file, :previous_block_num, :previous_hash, :previous_time, :addr_table

  def initialize(file_name)
    @file = File.open(file_name)
    @previous_block_num = -1
    @previous_hash = 0
    @previous_time = -1
  end
  
  def main
    @file.each do |line|
      blk_num, old_hash, trans, time, new_hash = split(line)
      puts (blk_num<<old_hash<<trans<<time<<new_hash) 
      block_arr = (line[0...line.rindex('|')]).unpack('U*') 
      puts calculate_hash(block_arr)	
    end
  end

  def split(line)
    index = 0
    temp_arr = Array.new()
    (0...5).each do |x|
      temp_index = line.index('|',index+1)
      temp_index = line.length if temp_index.nil?
      
      temp_arr[x] = line[index...temp_index]
      index = temp_index
    end
    temp_arr
  end

  def calculate_hash(block)
    sum = 0
    block.each do |char|
       sum = (sum + hash(char)) % 65536
    end
    sum.to_s(16)
  end

  def hash(x)
    ((x ** 3000) + (x ** x) - (3 ** x )) * (7 ** x)
  end
end

verify = Verifier.new(ARGV[0])
verify.main
