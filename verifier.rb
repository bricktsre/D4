# frozen_string_literal: true

require_relative 'blockchain_checker'

Flamegraph.generate('verify.html') do
  checker = BlockchainChecker.new(ARGV[0])
  checker.main
end
