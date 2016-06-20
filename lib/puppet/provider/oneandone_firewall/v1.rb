require 'oneandone'

Puppet::Type.type(:oneandone_firewall).provide(:v1) do
  desc 'Manages 1&1 fireall policies.'

  confine feature: :oneandone

  mk_resource_methods

  def initialize(*args)
    self.class.client
    super(*args)
  end

  def self.client
    OneAndOne.start(ENV['ONEANDONE_API_KEY'])
  end

  def self.instances
    OneAndOne.start(ENV['ONEANDONE_API_KEY'])
    firewall = OneAndOne::Firewall.new

    firewalls = []
    firewall.list.each do |fw|
      firewalls << new(instance_to_hash(fw))
    end
    firewalls
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.instance_to_hash(instance)
    {
      id: instance['id'],
      name: instance['name'],
      description: instance['description'],
      rules: rules_from_instance(instance),
      server_ips: servers_from_instance(instance),
      ensure: :present
    }
  end
  
  def self.rules_from_instance(instance)
    rules = []
    instance['rules'].each do |rule|
      rules.push(
        protocol: rule['protocol'],
        port_from: rule['port_from'],
        port_to: rule['port_to'],
        source: rule['source']
      )
    end
    rules
  end
  
  def self.servers_from_instance(instance)
    servers = []
    if !instance['server_ips'].nil?
      instance['server_ips'].each do |server|
        servers.push(server['ip'])
      end
    end
    servers unless servers.empty?
  end

  def server_ips=(value)
    firewall = OneAndOne::Firewall.new
    assign_server_ips(firewall, value)
    remove_server_ips(firewall, value)
  end

  def description=(value)
    Puppet.info("Modifying firewall policy description.")
    firewall = OneAndOne::Firewall.new
    firewall.modify(firewall_id: @property_hash[:id], description: value)
  end
  
  def exists?
    Puppet.info("Checking if firewall policy '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.info("Creating a new firewall policy '#{name}'.")
    firewall = OneAndOne::Firewall.new
    firewall.create(
      name: name,
      description: resource['description'],
      rules: resource[:rules]
    )

    firewall.wait_for(timeout: 100, interval: 2)

    @property_hash[:id] = firewall.id
    @property_hash[:ensure] = :present
    
    unless resource[:server_ips].nil? || resource[:server_ips].empty?
      assign_server_ips(firewall, resource[:server_ips]) 
    end
  end

  def destroy
    firewall = OneAndOne::Firewall.new
    Puppet.info("Deleting firewall policy '#{name}'.")
    firewall.delete(firewall_id: @property_hash[:id])
    firewall.wait_for(timeout: 200, interval: 2)
    @property_hash[:ensure] = :absent
  rescue => e
    raise(e.message) unless e.message.include? 'NOT_FOUND'
  end
  
  private
  
  def assign_server_ips(firewall, value)
    server_ip_list = firewall.ips(firewall_id: @property_hash[:id])
    
    old_ips = server_ip_list.collect {|e| e['ip']}.sort
    new_ips = value.to_a.sort
    
    unless old_ips.eql?(new_ips)
      # get the list of all public IPs
      public_ip = OneAndOne::PublicIP.new.list
          
      # verify IPs which are to be assigned and get IDs
      ids = []
      new_ips.select {|ip| !old_ips.include?(ip)}.each do |ip|
        ip_add = public_ip.select { |a| a['ip'] == ip }
        raise "IP address '#{ip}' could not be found." if ip_add.empty?
        ids.push(ip_add[0]['id'])
      end
      
      # assign IPs to the firewall policy
      unless ids.empty?
        Puppet.info("Assigning IPs to firewall policy '#{name}'.")
          firewall.add_ips(ips: ids)
          firewall.wait_for(timeout: 100, interval: 5)
      end  
    end
  end
  
  def remove_server_ips(firewall, value)
    server_ip_list = firewall.ips(firewall_id: @property_hash[:id])
    
    old_ips = server_ip_list.collect {|e| e['ip']}.sort
    new_ips = value.to_a.sort
    
    unless old_ips.eql?(new_ips)
      # get the list of all public IPs
      public_ip = OneAndOne::PublicIP.new.list
          
      # select IPs to be unassigned
      old_ips.select {|ip| !new_ips.include?(ip)}.each do |ip|
        
        # verify that the IP exists and find its ID
        ip_rm = public_ip.select { |a| a['ip'] == ip }
        
        unless ip_rm.empty?
          Puppet.info("Removing IP address '#{ip}' from firewall policy '#{name}'.")
          firewall.remove_ip(ip_id: ip_rm[0]['id'])
          firewall.wait_for(timeout: 100, interval: 5)
        else
          raise "IP address '#{ip}' could not be found."
        end
      end
    end
  end
  
end
