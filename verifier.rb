# frozen_string_literal: true

require_relative 'blockchain_checker'

def check_arguments(argv)
	return false if argv.size > 1 || argv.size == 0

	return false unless File.exist?(argv[0])

	true
end

Flamegraph.generate('verify.html') do
  if check_arguments(ARGV)
    checker = BlockchainChecker.new(ARGV[0])
    checker.main
  end
end
