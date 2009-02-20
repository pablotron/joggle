#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))

require 'jitter/runner/pstore'

Jitter::Runner::PStore.run({
  'runner.client.user' => ENV['JITTER_USERNAME'],
  'runner.client.pass' => ENV['JITTER_PASSWORD'],
})
