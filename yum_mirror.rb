#!/usr/bin/env ruby

require 'rsync'
require 'optparse'
require 'yaml'
require 'pp'
require 'fileutils'


def load_config()
	#Load config
	config_path='/config.yaml'
	options=YAML::load(open(File.expand_path(config_path)))
	return options
end

def load_mirrors(options)
	return options[:mirrors]
end

def mirror_sync_rsync (mirror)
	Rsync.run("#{mirror[:url]}", "#{mirror[:dest]}", ["-av","--progress","--delete"]) do |result|
		if result.success?
			result.changes.each do |change|
				puts "#{change.filename} (#{change.summary})"
			end
		else
			puts result.error
		end
	end
end

def mirror_sync_reposync(mirror)
	#Need to make tmp .repo file
	tmp_repo_file="/tmp.repo"
	tmp_repo_contents="[.]\nname=.\nbaseurl=#{mirror[:url]}\ngpgcheck=0\ngpgkey="
	File.open(tmp_repo_file, 'w') { |file| file.write(tmp_repo_contents) }
	#run reposync
	reposync_cmd="/usr/bin/reposync -c /tmp.repo --repoid='.' -p #{mirror[:dest]}"
	`#{reposync_cmd}`
	#Generate repo data
	`/usr/bin/createrepo --update #{mirror[:dest]}/`
end

def mirror_hardlink_datestamp(mirror)
	if File.directory?("#{mirror[:dest]}.#{datestamp}/")
		puts "#{mirror[:dest]}.#{datestamp}/ already exists, skipping!"
	else
		`mkdir -p  #{mirror[:dest]}.#{datestamp}/`
		`cp -R -l -v #{mirror[:dest]}/* #{mirror[:dest]}.#{datestamp}/`
	end
end

def mirror_datestamp(mirror)
	datestamp = "#{Time.now.strftime('%Y-%m-%d')}"
	if mirror[:hardlink_datestamp]
		mirror_hardlink_datestamp(mirror)
	else
		`mv #{mirror[:dest]} #{mirror[:dest]}.#{datestamp}`
		if mirror[:link_datestamp]
			`ln -s $(basename #{mirror[:dest]}.#{datestamp}) #{mirror[:dest]}`
		end
	end
end

def global_hardlink(hardlink_dir)
	puts "Running hardlink on #{hardlink_dir}"
	`/usr/sbin/hardlink -vv #{hardlink_dir}`
end

def all_repo(options,mirrors)
	puts "Making 'all' mirror(s) (#{options[:all_name]})"
	#For each mirrors.each[:dist] we can find, make an 'all' repo
	#which is really just hardlinks to all rpms, and one giant metadata
	dists=Array.new
	mirrors.each_pair do |name,mirror|
		if dists.include?(mirror[:dist])
			next
		else
			dists.push(mirror[:dist])
		end
	end
	#We have a list of dists.
	dists.each do |dist|
		dest = "#{options[:mirror_base]}/#{dist}/#{options[:all_name]}"
		unless File.directory?(dest)
			FileUtils.mkdir_p(dest)
		end
		mirrors.each_pair do |name,mirror|
			if mirror[:dist] == dist
				puts "Hardlinking #{options[:mirror_base]}/#{dist}/#{name}/*.rpm #{dest}"
				rpms=Dir.glob("#{options[:mirror_base]}/#{dist}/#{name}/**/*.rpm")
				rpms.each do |rpm|
					`cp -R -l -v #{rpm} #{dest}/`
				end
			else
				next
			end
		end
		#make the big repodata
		puts "Making repodata for #{options[:all_name]}"
		`/usr/bin/createrepo --update #{dest}/`
	end
end

options=load_config()
mirrors=load_mirrors(options)


mirrors.each_pair do |name,mirror|
	puts "Now syncing #{name}"
	#Check we have a 'dist'
	if !mirror[:dist]
		raise "Distirbution not specified for #{name}:#{mirror[:url]}!"
	else
		#Do we have a custom destination?
		if !mirror[:dest]
			mirror[:dest] = "#{options[:mirror_base]}/#{mirror[:dist]}/#{name}"
		end
		puts "Setting destination to #{mirror[:dest]}"
		#Make the destination if it doesn't exist
		dirname = File.dirname(mirror[:dest])
		unless File.directory?(dirname)
			FileUtils.mkdir_p(dirname)
		end
		case mirror[:type]
		when "rsync"
			mirror_sync_rsync(mirror)
		when "reposync"
			mirror_sync_reposync(mirror)
		else
			puts "Type #{mirror[:type]} not supported"
		end
		#See if we're supposed to datestamp and/or link the repo.
		if mirror[:datestamp]
			mirror_datestamp(mirror)
		end
	end
end
puts "Syncing done!"


if options[:hardlink] and options[:hardlink_dir]
	global_hardlink(options[:hardlink_dir])
end

if options[:all]
	all_repo(options,mirrors)
end
