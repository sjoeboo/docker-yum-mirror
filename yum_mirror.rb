#!/usr/bin/env ruby

require 'rsync'
require 'optparse'
require 'yaml'
require 'pp'

#Load config
config_path='/config.yaml'

mirrors=YAML::load(open(File.expand_path(config_path)))
mirrors.each_pair do |name,mirror|
  puts "Now syncing #{name}"
  case mirror[:type]
        when "rsync"
                pp mirror
                Rsync.run("#{mirror[:url]}", "#{mirror[:dest]}", ["-av","--progress","--delete"]) do |result|
                        if result.success?
                                result.changes.each do |change|
                                puts "#{change.filename} (#{change.summary})"
                        end
                        else
                                puts result.error
                        end
                end
        else
                puts "Type #{mirror[:type]} not supported"
        end
end
