#!/usr/bin/env ruby

# eye candy.
class String
  def red; colorize(self, "\e[1m\e[31m"); end
  def dark_red; colorize(self, "\e\[31m"); end
  def green; colorize(self, "\e[1m\e[32m"); end
  def dark_green; colorize(self, "\e[32m"); end
  def yellow; colorize(self, "\e[1m\e[33m"); end
  def dark_yellow; colorize(self, "\e[33m"); end
  def blue; colorize(self, "\e[1m\e[34m"); end
  def dark_blue; colorize(self, "\e[34m"); end
  def pur; colorize(self, "\e[1m\e[35m"); end
  def dark_pur; colorize(self, "\e[35m"); end
  def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
    
  def numeric?
    true if Float(self) rescue false
  end
end
# more descriptive load errors!
begin
  require 'rubygems'
  require 'pivotal-tracker'
  require 'plist'
  require "optparse"
rescue LoadError => e
  puts "
  A required gem was not found on your system.
  Type '#{"sudo gem install #{e.to_s.split('--')[1].strip}".red}#{"' to install it.".dark_red}
  ".dark_red
  exit
end
# tacks


# yeah baby!
class Main
  def initialize
    PivotalTracker::Client.token = File.open("#{ENV['HOME']}/.ptkey", "r").read if File.exist?("#{ENV['HOME']}/.ptkey")
    @options = {}
    optparse = OptionParser.new do |opts|
      opts.on('-h', '--help', "You're looking at it!") { puts opts; exit }
      opts.on('-gk', '--getkey USER:PASSWORD', "retrieve your apikey and save it") { |userpass| 
        userpass =~ /^(.+):(.+)$/ ? getkey(userpass) : raise(OptionParser::MissingArgument) 
      }
      opts.on('-sk', '--savekey APIKEY', "save your api key") { |key| savekey(key) }
      opts.on('-dk', '--deletekey', "delete your saved apikey") { deletekey }
      opts.on('-t', '--type bug,chore,etc', "Apply a type filter on the item") { |types | applyTypes types}
      opts.on('-l', '--list', "lists your projects" ) { list }
      opts.on('', '--label example,label', "Apply a label filter on the item") { |labels| applyLabels labels }
      opts.on('', '--id storyid', "show only story matching corrosponding id") { |id| applyId id }
      opts.on('-s', '--stories PROJECTNAME/ID [--label (example,labels) --type (bug,etc)]', "list stories for the refenced project name or id") { |ref| 
        stories ref 
      }
  
    end
    begin
      optparse.parse!
    rescue OptionParser::MissingArgument => e
      puts e
    end
  end
  def getkey info
    userpass = info.split(':')
    begin
      key = PivotalTracker::Client.token(userpass[0], userpass[1])
      puts "Your apikey is: #{key}".dark_blue
      savekey key
    rescue RestClient::Request::Unauthorized => e
      puts "Your password and/or username is incorrect.".dark_red
    end
  end
  def savekey key
    File.open("#{ENV['HOME']}/.ptkey","w").write(key)
    puts "Key saved to '#{ENV['HOME']}/.ptkey' use --deletekey to remove it"
  end
  def list
    begin
      projects = PivotalTracker::Project.all
      projects.each do |project|
        puts "- #{project.name.dark_green} (#{project.id})"
        #puts "\taccount: #{project.account}"
        puts "\tlast activity: #{project.last_activity_at.strftime('%c')}" if !project.last_activity_at.nil?
      end
    rescue RestClient::Request::Unauthorized => e
      puts "You need to be logged in to use this (try --help).".dark_red
    end
  end
  def stories ref
    ref = name2id ref if !ref.numeric?
    if ref.nil?
      puts "Story name or id is invalid"
      exit 
    end
    project = PivotalTracker::Project.find(ref)
    iterproject = project.stories.all if @labels.nil? and @types.nil? and @id.nil?
    iterproject = project.stories.all(:story_type => @types) if @labels.nil? and !@types.nil?  and @id.nil?
    iterproject = project.stories.all(:label => @labels, :story_type => @types) if !@labels.nil?  and @id.nil?
    iterproject = project.stories.find(@id) if !@id.nil?
    iterproject.each do |story|
      puts "- #{story.name.dark_green} (#{story.id})"
      puts "\ttype: #{story.story_type.gsub(/bug/,"bug".dark_red).gsub(/feature/,"feature".dark_yellow).gsub(/release/,"release".dark_green)}" if !story.story_type.nil?
      puts "\trequested by: #{story.requested_by}" if !story.requested_by.nil?
      puts "\tassigned to: #{story.owned_by}" if !story.owned_by.nil?
      puts "\tcreated on: #{story.created_at.strftime('%c')}" if !story.created_at.nil?
      puts "\taccepted on: #{story.accepted_at.strftime('%c')}" if !story.accepted_at.nil?
      puts "\turl: #{story.url}" if !story.url.nil?
      puts "\tlabels: #{story.labels}" if !story.labels.nil?
      puts "\tdescription: #{story.description}" if !story.description.nil? and story.description.strip != ""
      puts "\tnotes: " if !story.notes.all.nil? and story.notes.all.length != 0
      story.notes.all.each do |note|
        puts "\t\t#{note.author}: #{note.text.strip} [#{note.noted_at.strftime('%c')}]"
      end
    end
  end
  def applyLabels labels
    @labels = labels.split(',')
  end
  def applyTypes types
    @types = types.split(',')
  end
  def applyId id
    @id = id
  end
  private
    def name2id name
      projects = PivotalTracker::Project.all
      projectid = nil
      projects.each { |project| projectid = project.id if project.name.downcase == name.downcase }
      projectid
    end

  
end

main = Main.new
