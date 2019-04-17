# frozen_string_literal: true

require_relative 'blockchain_checker'
require "benchmark"

def check_arguments(argv)
	return false if argv.size > 1 || argv.size == 0

	return false unless File.exist?(argv[0])

	true
end

Flamegraph.generate('verify.html') do
  if check_arguments(ARGV)
  	time = Benchmark.realtime do
    	checker = BlockchainChecker.new(ARGV[0])
    	checker.main
    end
    puts "Time elapsed #{time*1000} milliseconds"
  end
end
