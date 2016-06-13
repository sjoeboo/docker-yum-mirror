#!/usr/bin/env ruby

require 'rsync'
require 'optparse'
require 'yaml'
require 'pp'
require 'fileutils'

#Load config
config_path='/config.yaml'

options=YAML::load(open(File.expand_path(config_path)))
mirrors=options[:mirrors]
pp options
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
  when "reposync"
    #Need to make tmp .repo file
    tmp_repo_file="/tmp.repo"
    tmp_repo_contents="[.]\nname=.\nbaseurl=#{mirror[:url]}\ngpgcheck=0\ngpgkey="
    File.open(tmp_repo_file, 'w') { |file| file.write(tmp_repo_contents) }
    #run reposync
    reposync_cmd="/usr/bin/reposync -c /tmp.repo --repoid='.' -p #{mirror[:dest]}"
    `#{reposync_cmd}`
    #Generate repo data
    `/usr/bin/createrepo --update #{mirror[:dest]}/`
	else
    puts "Type #{mirror[:type]} not supported"
  end
  #See if we're supposed to datestamp and/or link the repo.
  if mirror[:datestamp]
    datestamp = "#{Time.now.strftime('%Y-%m-%d')}"
    if mirror[:hardlink_datestamp]
      `mkdir -p  #{mirror[:dest]}.#{datestamp}/`
      `cp -R -l -v #{mirror[:dest]}/* #{mirror[:dest]}.#{datestamp}/`
    else
      `mv #{mirror[:dest]} #{mirror[:dest]}.#{datestamp}`
      if mirror[:link_datestamp]
        `ln -s $(basename #{mirror[:dest]}.#{datestamp}) #{mirror[:dest]}`
      end
    end
  end
end
puts "Syncing done!"
if options[:hardlink] and options[:hardlink_dir]
  puts "Running hardlink on #{options[:hardlink_dir]}"
  `/usr/sbin/hardlink -vv #{options[:hardlink_dir]}`
end
