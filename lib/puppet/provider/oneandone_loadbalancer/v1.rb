require 'oneandone'

Puppet::Type.type(:oneandone_loadbalancer).provide(:v1) do
  desc 'Manages 1&1 load balancers.'

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
    loadbalancer = OneAndOne::LoadBalancer.new

    loadbalancers = []
    loadbalancer.list.each do |lb|
      loadbalancers << new(instance_to_hash(lb))
    end
    loadbalancers
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
      datacenter: instance['datacenter']['country_code'],
      description: instance['description'],
      method: instance['method'],
      health_check_test: instance['health_check_test'],
      health_check_interval: instance['health_check_interval'],
      persistence: instance['persistence'],
      persistence_time: instance['persistence_time'],
      health_check_path: instance['health_check_path'],
      health_check_parse: instance['health_check_parse'],
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
        port_balancer: rule['port_balancer'],
        port_server: rule['port_server'],
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
    loadbalancer = OneAndOne::LoadBalancer.new
    assign_server_ips(loadbalancer, value)
    remove_server_ips(loadbalancer, value)
  end

  def description=(value)
    Puppet.info("Modifying load balancer 'description' property.")
    loadbalancer = OneAndOne::LoadBalancer.new
    loadbalancer.modify(load_balancer_id: @property_hash[:id], description: value)
  end

  def persistence=(value)
    Puppet.info("Modifying load balancer 'persistence' property.")
    set_persistence_properties
  end

  def persistence_time=(value)
    Puppet.info("Modifying load balancer 'persistence_time' property.")
    if resource[:persistence] == :false
      Puppet.warning("You may not set 'persistence_time' value if 'persistence' is false.")
    else
      set_persistence_properties
    end
  end

  def health_check_test=(value)
    Puppet.info("Modifying load balancer 'health_check_test' property.")
    set_health_check_properties
  end

  def health_check_interval=(value)
    Puppet.info("Modifying load balancer 'health_check_interval' property.")
    if resource[:health_check_test] == 'NONE'
      Puppet.warning("You may not set 'health_check_interval' value if 'health_check_test' is 'NONE'.")
    else
      set_health_check_properties
    end
  end

  def health_check_path=(value)
    Puppet.info("Modifying load balancer 'health_check_path' property.")
    loadbalancer = OneAndOne::LoadBalancer.new
    loadbalancer.modify(load_balancer_id: @property_hash[:id], health_check_path: value)
  end

  def health_check_parse=(value)
    Puppet.info("Modifying load balancer 'health_check_parse' property.")
    loadbalancer = OneAndOne::LoadBalancer.new
    loadbalancer.modify(load_balancer_id: @property_hash[:id], health_check_parse: value)
  end

  def method=(value)
    Puppet.info("Modifying load balancer 'method' property.")
    loadbalancer = OneAndOne::LoadBalancer.new
    loadbalancer.modify(load_balancer_id: @property_hash[:id], method: value)
  end

  def rules=(value)
    loadbalancer = OneAndOne::LoadBalancer.new
    lb_rules = loadbalancer.rules(load_balancer_id: @property_hash[:id])

    old_rules = get_old_rules(lb_rules)
    new_rules = value.sort {|r1, r2| [r1['protocol'],r1['port_balancer']] <=> [r2['protocol'],r2['port_balancer']]}

    remove_rules(loadbalancer, lb_rules, old_rules, new_rules)

    # list the current rules again and update old rules
    lb_rules = loadbalancer.rules(load_balancer_id: @property_hash[:id])
    old_rules = get_old_rules(lb_rules)

    add_rules(loadbalancer, old_rules, new_rules)
  end
  
  def exists?
    Puppet.info("Checking if load balancer '#{name}' exists.")
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.info("Creating a new load balancer '#{name}'.")
    loadbalancer = OneAndOne::LoadBalancer.new
    loadbalancer.create(
      name: name,
      description: resource['description'],
      datacenter_id: datacenter_id_from_code(resource[:datacenter]),
      method: resource['method'],
      health_check_test: resource['health_check_test'],
      health_check_interval: resource['health_check_interval'],
      persistence: resource['persistence'],
      persistence_time: resource['persistence_time'],
      health_check_path: resource['health_check_path'],
      health_check_parse: resource['health_check_parse'],
      rules: resource[:rules]
    )

    loadbalancer.wait_for(timeout: 100, interval: 5)

    @property_hash[:id] = loadbalancer.id
    @property_hash[:ensure] = :present
    
    unless resource[:server_ips].nil? || resource[:server_ips].empty?
      assign_server_ips(loadbalancer, resource[:server_ips]) 
    end
  end

  def destroy
    loadbalancer = OneAndOne::LoadBalancer.new
    Puppet.info("Deleting load balancer '#{name}'.")
    loadbalancer.delete(load_balancer_id: @property_hash[:id])
    loadbalancer.wait_for(timeout: 100, interval: 5)
    @property_hash[:ensure] = :absent
  rescue => e
    raise(e.message) unless e.message.include? 'NOT_FOUND'
  end

  def rules_deep_equal?(old_rules, new_rules)
    return false unless old_rules.length == new_rules.length

    for i in 0..(old_rules.length - 1)
      unless old_rules[i][:protocol] == new_rules[i]['protocol'] &&
             old_rules[i][:port_balancer] == new_rules[i]['port_balancer'] &&
             old_rules[i][:port_server] == new_rules[i]['port_server'] &&
             old_rules[i][:source] == new_rules[i]['source']
        return false
      end
    end

    true
  end
  
  private

  def set_health_check_properties
    loadbalancer = OneAndOne::LoadBalancer.new
    interval = resource[:health_check_test] == 'NONE' ? 0 : resource[:health_check_interval]
    loadbalancer.modify(load_balancer_id: @property_hash[:id], health_check_test: resource[:health_check_test], health_check_interval: interval)
  end

  def set_persistence_properties
    loadbalancer = OneAndOne::LoadBalancer.new
    interval = resource[:persistence] ? resource[:persistence_time] : 0
    loadbalancer.modify(load_balancer_id: @property_hash[:id], persistence: resource[:persistence], persistence_time: interval)
  end

  def datacenter_id_from_code(country_code)
    unless country_code.nil? || country_code == ''
      datacenter = OneAndOne::Datacenter.new
      datacenter.list.each do |dc|
        return dc['id'] if dc['country_code'] == country_code.to_s.upcase
      end
      raise "Data center with country code '#{country_code}' could not be found."
    end
    nil
  end
  
  def assign_server_ips(loadbalancer, value)
    server_ip_list = loadbalancer.ips(load_balancer_id: @property_hash[:id])
    
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
      
      # assign IPs to the load balancer
      unless ids.empty?
        Puppet.info("Assigning IPs to load balancer '#{name}'.")
          loadbalancer.add_ips(ips: ids)
          loadbalancer.wait_for(timeout: 100, interval: 5)
      end  
    end
  end
  
  def remove_server_ips(loadbalancer, value)
    server_ip_list = loadbalancer.ips(load_balancer_id: @property_hash[:id])
    
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
          Puppet.info("Removing IP address '#{ip}' from load balancer '#{name}'.")
          loadbalancer.remove_ip(ip_id: ip_rm[0]['id'])
          loadbalancer.wait_for(timeout: 100, interval: 5)
        else
          raise "IP address '#{ip}' could not be found."
        end
      end
    end
  end

  def get_old_rules(lb_rules)
    old_rules = []
    # sort by 'protocol' then by 'port_balancer', protocol + port_balancer is unique per rule
    lb_rules.sort {|r1, r2| [r1['protocol'],r1['port_balancer']] <=> [r2['protocol'],r2['port_balancer']]}.each do |r|
      data = {
        'protocol' => r['protocol'],
        'port_balancer' => r['port_balancer'],
        'port_server' => r['port_server'],
        'source' => r['source']
      }
      old_rules << data
    end
    old_rules
  end

  def add_rules(lb, old_rules, new_rules)
    diff = new_rules - old_rules
    unless diff.empty?
      Puppet.info("Adding new rules...")
      lb.add_rules(load_balancer_id: @property_hash[:id], rules: diff)
      lb.wait_for(timeout: 100, interval: 5)
    end
  end

  def remove_rules(lb, lb_rules, old_rules, new_rules)
    diff = old_rules - new_rules
    for i in 0..(diff.length - 1)
      unless i == (old_rules.length - 1)
        rule_id = lb_rules.select {|r| r['protocol'] == diff[i]['protocol'] && r['port_balancer'] == diff[i]['port_balancer']}[0]['id']
        Puppet.info("Removing the rule with ID '#{rule_id}'...")
        lb.remove_rule(load_balancer_id: @property_hash[:id], rule_id: rule_id)
        lb.wait_for(timeout: 100, interval: 5)
      else
        raise "It's not allowed to remove all rules from the load balancer."
      end
    end
  end
end
