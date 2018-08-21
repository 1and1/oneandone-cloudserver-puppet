require 'puppet/parameter/boolean'

Puppet::Type.newtype(:oneandone_server) do
  @doc = 'Type representing a 1&1 Cloud server.'

  newproperty(:ensure) do
    newvalue(:present) do
      provider.create(:present) unless provider.running?
    end

    newvalue(:absent) do
      provider.destroy if provider.exists?
    end

    newvalue(:running) do
      provider.create(:running) unless provider.running?
    end

    newvalue(:stopped) do
      provider.stop unless provider.stopped?
    end

    def change_to_s(current, desired)
      current = :running if current == :present
      desired = :running if desired == :present
      current == desired ? current : "changed #{current} to #{desired}"
    end

    def insync?(is)
      is = :present if is == :running
      is = :stopped if is == :stopping
      is.to_s == should.to_s
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the server.'
    validate do |value|
      raise('Server must have a name') if value == ''
      raise('Name should be a String') unless value.is_a?(String)
    end
  end

  newparam(:keep_ips) do
    desc 'Whether the server IPs should be removed with the server.'
    defaultto :false
    newvalues(:true, :false)
  end

  newparam(:force_stop) do
    desc 'Whether to use the hardware method to power off the server.'
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:ip_address) do
    desc 'The IP address to be used for the server.'
    validate do |value|
      raise('IP address must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:ram) do
    desc 'The amount of RAM in GB assigned to the server.'
    validate do |value|
      raise('Server must have RAM assigned.') if value.nil?
    end
    munge do |value|
      Float(value)
    end
  end

  newproperty(:virtual_processors) do
    desc 'The number of virtual processors assigned to the server.'
    validate do |value|
      raise('Server must have processors assigned.') if value.nil?
      raise('Processor number must be an integer.') unless value.is_a?(Integer)
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:cores_per_processor) do
    desc 'The number of cores per processor assigned to the server.'
    validate do |value|
      raise('Server must have a number of cores per processor.') if value.nil?
      raise('Number of cores per processor must be an integer.') unless value.is_a?(Integer)
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:datacenter) do
    desc 'The data center where the server is deployed.'
    defaultto 'US'
  end

  newproperty(:id) do
    desc 'The server ID.'
  end

  newproperty(:description) do
    desc 'The server description.'
    validate do |value|
      raise('Server description must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:password) do
    desc 'The password of the server.'
    validate do |value|
      raise('Server password must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:rsa_key) do
    desc 'The rsa key to be enabled on the server for SSH.'
    validate do |value|
      raise('SSH key must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:firewall_id) do
    desc 'The firewall ID used for the server.'
    validate do |value|
      raise('Firewall ID must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:load_balancer_id) do
    desc 'The load balancer ID used for the server.'
    validate do |value|
      raise('Load balancer ID must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:monitoring_policy_id) do
    desc 'The monitoring policy ID used for the server.'
    validate do |value|
      raise('Monitoring policy ID must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:ips, array_matching: :all) do
    desc 'The IP addresses assigned to the server.'
    validate do |value|
      raise('IP address must be an Array.') unless value.is_a?(Array)
    end
  end

  newproperty(:hdds, array_matching: :all) do
    desc 'The hard disks of the server.'
  end

  newproperty(:image) do
    desc 'The OS image name of the server.'
    validate do |value|
      raise('Image name must be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:appliance_id) do
    desc 'The ID of the server OS appliance.'
    validate do |value|
      raise('Server must have appliance ID specified') if value == ''
      raise('The appliance ID must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:server_type) do
    desc 'Type of the server (cloud or baremetal).'
    validate do |value|
      raise('The server type must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:baremetal_model_id) do
    desc 'ID of the desired baremetal model.'
    validate do |value|
      raise('The baremetal model id must be a String') unless value.is_a?(String)
    end
  end

  newproperty(:server_size) do
    desc 'The server size.'
    defaultto 'FLEX'
    # newvalues ('S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL', '5XL', 'FLEX')
  end
end
