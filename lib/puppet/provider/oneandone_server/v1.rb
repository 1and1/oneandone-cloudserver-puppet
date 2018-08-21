require 'oneandone'

Puppet::Type.type(:oneandone_server).provide(:v1) do
  desc 'Manages 1&1 cloud servers.'

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
    srv = OneAndOne::Server.new

    servers = []
    srv.list.each do |server|
      hash = server_to_hash(server)
      servers << new(hash)
    end
    servers
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov if resource[:name] == prov.name
      end
    end
  end

  def self.server_to_hash(instance)
    vm_state = instance['status']['state']
    state = if %w(POWERED_OFF POWERING_OFF).include?(vm_state)
              :stopped
            else
              :present
            end

    config = {
      id: instance['id'],
      datacenter: instance['datacenter']['country_code'],
      name: instance['name'],
      description: instance['description'],
      virtual_processors: !instance['hardware'].nil? ? instance['hardware']['vcore'] : '',
      cores_per_processor: !instance['hardware'].nil? ? instance['hardware']['cores_per_processor'] : '',
      ram: !instance['hardware'].nil? ? instance['hardware']['ram'] : '',
      image: !instance['image'].nil? ? instance['image']['name'] : '',
      ips: ips_from_instance(instance),
      hdds: hdds_from_instance(instance),
      server_type: instance['server_type'],
      baremetal_model_id: instance['baremetal_model_id'],
      ensure: state
    }

    config
  end
  
  def self.ips_from_instance(instance)
    ips = []
    instance['ips'].each { |ip| ips.push(ip['ip']) } unless instance['ips'].nil?
    ips unless ips.empty?
  end
  
  def self.hdds_from_instance(instance)
    hdds = []
    if !instance['hardware'].nil? && !instance['hardware']['hdds'].nil?
      instance['hardware']['hdds'].each do |hdd|
        hdds.push(size: hdd['size'], is_main: hdd['is_main'])
      end
    end
    hdds unless hdds.empty?
  end

  def exists?
    Puppet.info("Checking if server '#{name}' exists.")
    running? || stopped?
  rescue
    false
  end

  def running?
    Puppet.info("Checking if server '#{name}' is running.")
    [:present, :pending, :running].include? @property_hash[:ensure]
  end

  def stopped?
    Puppet.info("Checking if server '#{name}' is stopped.")
    [:stopping, :stopped].include? @property_hash[:ensure]
  end

  def create(state)
    if stopped?
      start
    else

      Puppet.info("Creating a new server named '#{name}' in '#{state}' state.")
      server = OneAndOne::Server.new
      server.create(
        name: name,
        description: resource['description'],
        datacenter_id: datacenter_id_from_code(resource[:datacenter]),
        fixed_instance_id: server_size_id_from_name(resource[:server_size]),
        appliance_id: resource[:appliance_id],
        power_on: (state != :stopped),
        password: resource[:password],
        rsa_key: resource[:rsa_key],
        firewall_id: resource[:firewall_id],
        ip_id: ip_id_from_address(resource[:ip_address]),
        load_balancer_id: resource[:load_balancer_id],
        monitoring_policy_id: resource[:monitoring_policy_id],
        vcore: resource[:virtual_processors],
        cores_per_processor: resource[:cores_per_processor],
        ram: resource[:ram],
        hdds: resource[:hdds],
        server_type: resource[:server_type],
        baremetal_model_id: resource[:baremetal_model_id]
      )

      server.wait_for(timeout: 25, interval: 15)

      @property_hash[:id] = server.id
      @property_hash[:ensure] = state
    end
  end

  def start
    Puppet.info("Starting server '#{name}'.")
    server = OneAndOne::Server.new
    server.change_status(server_id: @property_hash[:id], action: 'POWER_ON')
    server.wait_for
    @property_hash[:ensure] = :present
  end

  def stop
    if exists?
      method = resource['force_stop'] ? 'HARDWARE' : 'SOFTWARE'
      Puppet.info("Stopping server '#{name}' using #{method} method.")
      server = OneAndOne::Server.new
      server.change_status(server_id: @property_hash[:id], action: 'POWER_OFF', method: method)
      server.wait_for
      @property_hash[:ensure] = :stopped
    else
      create(:stopped)
    end
  end

  def destroy
    server = OneAndOne::Server.new
    Puppet.info("Deleting server '#{name}'.")
    server.delete(server_id: @property_hash[:id], keep_ips: resource[:keep_ips])
    server.wait_for
    @property_hash[:ensure] = :absent
  rescue => e
    raise(e.message) unless e.message.include? 'NOT_FOUND'
  end

  private

  def server_size_id_from_name(server_size)
    if !server_size.nil? && server_size != 'FLEX'
      server = OneAndOne::Server.new
      server.list_fixed.each do |size|
        return size['id'] if size['name'] == server_size.to_s.upcase
      end
      raise "Fixed server size '#{server_size}' could not be found."
    end
    nil
  end

  def datacenter_id_from_code(country_code)
    unless country_code.nil?
      datacenter = OneAndOne::Datacenter.new
      datacenter.list.each do |dc|
        return dc['id'] if dc['country_code'] == country_code.to_s.upcase
      end
      raise "Data center with country code '#{country_code}' could not be found."
    end
    nil
  end

  def ip_id_from_address(address)
    unless address.nil?
      public_ip = OneAndOne::PublicIP.new
      public_ip.list.each do |ip|
        return ip['id'] if ip['assigned_to'].nil? && ip['ip'] == address
      end
      raise "No unassigned public IP address '#{address}' could be found."
    end
    nil
  end
end
