# change to false because true listen on "any" 
default[:bind9][:enable_ipv6] = false

# Allow all clients to query the nameserver, no recursion
default[:bind9][:allow_query] = nil
default[:bind9][:allow_recursion] = "none"

# Don:t allow to mess with zone files by default
default[:bind9][:allow_transfer] = "none"
default[:bind9][:allow_update] = nil

# set a forwarders to enable forwarding
default[:bind9][:forwarders] = nil
#default[:bind9][:forwarders] = [ "8.8.8.8", "8.8.4.4" ]

# by default listen on "any" ip address
default[:bind9][:listen_on] = [ "any" ]
#default[:bind9][:listen_on] = [ "key", "192.168.0.0/24" ]

case node[:platform]
when "centos", "redhat", "suse", "fedora"
  default[:bind9][:package] = "bind"
when "debian", "ubuntu"
  default[:bind9][:package] = "bind9"
end

default[:bind9][:service] = "bind9"