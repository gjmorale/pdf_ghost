#!/usr/bin/env ruby
require 'rubygems'
require 'pdf/reader'
require 'fileutils'
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

cleaner = Cleaner.new
cleaner.load "in", "../pdf_reader/dev/in", "source.private"
cleaner.execute