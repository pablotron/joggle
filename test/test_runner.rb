#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))

require 'joggle/runner/pstore'

Joggle::Runner::PStore.run({
  'runner.client.user' => ENV['JOGGLE_USERNAME'],
  'runner.client.pass' => ENV['JOGGLE_PASSWORD'],
})
