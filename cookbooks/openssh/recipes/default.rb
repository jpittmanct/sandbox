# Author:: Michael Kang <mkang@citytechinc.com>
# Cookbook Name:: openssh
# Recipe:: default
#
# Copyright 2012, CITYTECH, Inc.
# All rights reserved.

packages = case node["platform_family"]
  when "rhel","fedora"
    %w{ openssh-clients openssh }
  when "arch"
    %w{ openssh }
  else
    %w{ openssh-client openssh-server }
  end
  
packages.each do |pkg|
  package pkg
end

service "ssh" do
  case node["platform_family"]
  when "rhel","fedora","arch"
    service_name "sshd"
  else
    service_name "ssh"
  end
  supports value_for_platform(
    "debian" => { "default" => [ :restart, :reload, :status ] },
    "ubuntu" => {
      "8.04" => [ :restart, :reload ],
      "default" => [ :restart, :reload, :status ]
    },
    "centos" => { "default" => [ :restart, :reload, :status ] },
    "redhat" => { "default" => [ :restart, :reload, :status ] },
    "fedora" => { "default" => [ :restart, :reload, :status ] },
    "arch" => { "default" => [ :restart ] },
    "default" => { "default" => [:restart, :reload ] }
  )
  action [ :enable, :start ]
end

#template "/etc/ssh/sshd_config" do
#  source "sshd_config.erb"
#  owner "root"
#  group "root"
#  mode 0600
#end

# Set up authorized_keys2 file, with public keys from 'auxiliary' data bag -
# This databag normally contains only ctmsp admin keys, for root.
auxiliary_pubkey_info = data_bag_item("auxiliary", "openssh")

# Load public keys from 'credentials' data bag - we will normally place developer and
# client (non-root) keys here
pubkey_info = data_bag_item("credentials", node.chef_environment)



#
# For the ctmsp_access user, normally "root", add all our auxiliary openssh keys.  If there are
# non-auxiliary (non-admin basically) keys to add to the ctmsp_access "root" user then add those
# keys as well.
#
node["openssh"]["ctmsp_access"].each do |ctmsp_user|

  next if node["etc"]["passwd"][ctmsp_user].nil? || node["etc"]["passwd"][ctmsp_user].empty?
  user_directory = node["etc"]["passwd"][ctmsp_user]["dir"]

  next if user_directory.nil? || user_directory.empty?

	directory "#{user_directory}/.ssh" do
	  owner ctmsp_user
	  group ctmsp_user
	  mode "0700"
	  action :create
	end

  if !pubkey_info["openssh"].nil? && !pubkey_info["openssh"]["authkeys2_users"].nil?
    pubkey_info["openssh"]["authkeys2_users"].each do |non_ctmsp_user, non_ctmsp_keys|
  
      # if the non_ctmsp_user should be added for admin access to "root", then add them to the array
      if non_ctmsp_user == ctmsp_user
        auxiliary_pubkey_info["authkeys2"] += non_ctmsp_keys
      end
    end
  end


  # authorized_keys2 file
  template "#{user_directory}/.ssh/authorized_keys2" do
    source "authorized_keys2.erb"
    owner ctmsp_user
    group ctmsp_user
    mode "0600"
    variables(
      :publickeys => auxiliary_pubkey_info["authkeys2"]
    )
  end
end

directory "/opt/openssh" do
  owner "root"
  group "root"
  mode "0750"
	action :create
end

# Restart openssh script
template "/opt/openssh/restart_sshd.sh" do
  source "restart_sshd.sh.erb"
  owner "root"
  group "root"
  mode "0500"
end

# Schedule sshd restart
cron "restart_sshd" do
  minute  node["openssh"]["restart"]["minute"]
  hour    node["openssh"]["restart"]["hour"]
  day     node["openssh"]["restart"]["day"]
  month   node["openssh"]["restart"]["month"]
  weekday node["openssh"]["restart"]["weekday"]
  user "root"
  command "/opt/openssh/restart_sshd.sh >>/var/log/ctmsp/restart_sshd.log 2>&1"
  path "/usr/sbin:/usr/bin:/sbin:/bin"
  action node["openssh"]["restart"]["enabled"] == true ? :create : :delete
end



# Do not continue if the databag does not have the openssh variable
if !pubkey_info["openssh"] || !pubkey_info["openssh"]["authkeys2_users"]
  return nil
end

# Given the user and the authorized_keys array to use, and populate the file.	
pubkey_info["openssh"]["authkeys2_users"].each do |auth_user, keys_array|

  keys_aleady_added_for_linux_acct = false
  node["openssh"]["ctmsp_access"].each do |ctmsp_user|
    if ctmsp_user == auth_user
      Chef::Log.info("Not adding keys for user: #{auth_user}, as this user has already been added earlier in this recipe")
      keys_aleady_added_for_linux_acct = true
      break
    end
  end

  # skip to the next auth_user in this for loop
  next if keys_aleady_added_for_linux_acct == true

	Chef::Log.warn("Adding keys for user: #{auth_user}")
		
	begin		
		auth_user_homedir = File.expand_path("~#{auth_user}")
		Chef::Log.info("User #{auth_user}'s homedir: #{auth_user_homedir}")
	rescue ArgumentError
		Chef::Log.warn("User ~#{auth_user} does not exist.  Will not add ssh key.")
		auth_user_homedir = nil
	end
		
	directory "#{auth_user_homedir}" do
	  owner auth_user
	  group auth_user
	  mode "0755"
	  recursive true
	  action :create
	  not_if { auth_user_homedir.nil? || File.exists?(auth_user_homedir) }
	end	
			
	directory "#{auth_user_homedir}/.ssh" do
	  owner auth_user
#		  group auth_user
	  mode "0700"
	  action :create
	  not_if { auth_user_homedir.nil? }
	end	

	template "#{auth_user_homedir}/.ssh/authorized_keys2" do
	  source "authorized_keys2.erb"
	  owner auth_user
#		  group "root"
	  mode "0600"
	  variables(
	  	:publickeys => pubkey_info["openssh"]["authkeys2_users"][auth_user]
	  )
	  not_if { auth_user_homedir.nil? }
	end
end
