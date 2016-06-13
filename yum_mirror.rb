#!/usr/bin/env ruby

require 'rsync'
require 'optparse'
require 'yaml'
require 'pp'
require 'fileutils'

#Load config
config_path='/config.yaml'

mirrors=YAML::load(open(File.expand_path(config_path)))
mirrors.each_pair do |name,mirror|
	puts "Now syncing #{name}"
	#Make the destination if it doesn't exist
	dirname = File.dirname(mirror[:dest])
	unless File.directory?(dirname)
		FileUtils.mkdir_p(dirname)
	end
	case mirror[:type]
	 when "rsync"
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
