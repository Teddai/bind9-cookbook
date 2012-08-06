#
# Cookbook Name:: bind9
# Recipe:: default
#
# Copyright 2011, Mike Adolphs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "bind9::install"

freeze = execute "freeze update" do
  command "rndc freeze"
  returns [ 0 , 1 ]
  action :nothing
end

thaw = execute "thaw updates" do
  command "rndc thaw"
  returns [ 0 , 1 ]
  action :nothing
end

template "/etc/bind/named.conf.options" do
  source "named.conf.options.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/bind/named.conf.local" do
  source "named.conf.local.erb"
  owner "root"
  group "root"
  mode 0644
  variables({
    :zonefiles => search(:zones)
})
end

ruby_block "generate serial" do
  block do
    require "date"
    node.set[:bind9][:serial] = Time.now.utc.strftime("%Y%m%H%M")
    node.save
  end
  action :create
end

search(:zones).each do |zone|
  if ! zone['ddns']
    template "/var/cache/bind/#{zone['domain']}" do
      source "zonefile.erb"
      owner "bind"
      group "bind"
      mode 0644
      variables({
        :domain => zone['domain'],
        :soa => zone['zone_info']['soa'],
        :contact => zone['zone_info']['contact'],
        :serial => zone['zone_info']['serial'],
        :global_ttl => zone['zone_info']['global_ttl'],
        :nameserver => zone['zone_info']['nameserver'],
        :mail_exchange => zone['zone_info']['mail_exchange'],
        :records => zone['zone_info']['records']
      })
      end
  else
    freeze.run_action(:run)
    template "/var/cache/bind/#{zone['domain']}" do
      source "zonefile_ddns.erb"
      owner "bind"
      group "bind"
      mode 0644
      variables(
        :file => "/var/cache/bind/#{zone['domain']}.header"
        )
      action :create_if_missing
    end
    template "/var/cache/bind/#{zone['domain']}.header" do
      source "zonefile.erb"
      owner "bind"
      group "bind"
      mode 0644
      variables(
        :domain => zone['domain'],
        :soa => zone['zone_info']['soa'],
        :contact => zone['zone_info']['contact'],
          # update serial
        :serial => node[:bind9][:serial],
        :global_ttl => zone['zone_info']['global_ttl'],
        :nameserver => zone['zone_info']['nameserver'],
        :mail_exchange => zone['zone_info']['mail_exchange'],
        :records => zone['zone_info']['records']
      )
#      notifies :reload , "service[bind9]"
    end
    thaw.run_action(:run)
  end  
end
