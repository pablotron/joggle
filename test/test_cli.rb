#!/usr/bin/env ruby

# get current directory
CWD = File.dirname(__FILE__)

# add ../lib to load path
$LOAD_PATH.unshift(File.join(CWD, '../lib'))

# run ../bin/joggle
load File.join(CWD, '../bin/joggle')
