#!/usr/bin/env ruby
#
# Get and clone all forks of a Github org. (with filter)
# Copyright (C) 2014  Sebastien Badia <sebastien.badia@enovance.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'octokit'

# Internal variables
script_path = File.expand_path(File.dirname(__FILE__))

track="#{script_path}/track-upstream.sh"
repoupdate = []
gh_org='enovance'
repo_filter='puppet|kibana|tempest'

if ENV['GITHUB_TOKEN'].nil?
  puts "GITHUB_TOKEN not set"
  exit 1
end

client = Octokit::Client.new :access_token => ENV['GITHUB_TOKEN']
# GitHub pagination limit results to 100 elements by pages (100 is the max, and 30 the default)
client.auto_paginate = true
repos = client.org_repos(gh_org, {:type => 'forks'})

repos.each do |r|
  if r[:name].match(/#{repo_filter}/)
    repoupdate << r[:name]
  end
end

puts "eNovance github forks (matching this patterns /#{repo_filter}/) : #{repoupdate.length}"

Dir.chdir(script_path)

repoupdate.each do |up|
  if File.directory?(up)
    Dir.chdir(up)
    system("git checkout master")
    system("git reset --hard")
    system("git clean -xfdq")
    system("git pull origin")
    system("bash #{track} #{up}")
    Dir.chdir(script_path)
  else
    system("git clone git@github.com:#{gh_org}/#{up}.git")
    Dir.chdir(up)
    system("bash #{track} #{up}")
    Dir.chdir(script_path)
  end
end
