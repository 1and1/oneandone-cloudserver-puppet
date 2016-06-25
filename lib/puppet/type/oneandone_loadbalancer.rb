require 'puppet/parameter/boolean'

Puppet::Type.newtype(:oneandone_loadbalancer) do
  @doc = 'Type representing a 1&1 load balancer.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the load balancer.'
    validate do |value|
      raise('The name should be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:rules, array_matching: :all) do
    desc 'The load balancer rules.'

    def insync?(is)
      if is.is_a? Array
        old_rules = is.sort {|i1, i2| [i1[:protocol], i1[:port_balancer]] <=> [i2[:protocol], i2[:port_balancer]]}
        new_rules = should.sort {|i1, i2| [i1['protocol'], i1['port_balancer']] <=> [i2['protocol'], i2['port_balancer']]}

        return provider.rules_deep_equal?(old_rules, new_rules)
      else
        return is == should
      end
    end
  end
  
  newproperty(:id) do
    desc 'The load balancer ID.'
  end

  newproperty(:description) do
    desc 'The load balancer description.'
  end

  newproperty(:datacenter, :readonly => true) do
    desc 'The data center where the load balancer is created.'
    defaultto 'US'

    def insync?(is)
      true
    end
  end

  newproperty(:persistence) do
    desc 'Persistence.'
    defaultto :false
    newvalues(:true, :false)

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:persistence_time) do
    desc 'The persistence time in seconds.'
    validate do |value|
      raise('Persistence time must be an integer.') unless value.is_a?(Integer)
    end
  end

  newproperty(:health_check_test) do
    desc 'Type of the health check.'
    defaultto 'NONE'
    newvalues('NONE', 'TCP', 'ICMP', 'HTTP')
  end

  newproperty(:health_check_interval) do
    desc 'The health check period in seconds.'
    validate do |value|
      raise('Health check period must be an integer.') unless value.is_a?(Integer)
    end
  end

  newproperty(:method) do
    desc 'The Load balancing method.'
    validate do |value|
      raise('Load balancing method is required.') if value.nil?
      raise('Load balancing method must be a string.') unless value.is_a?(String)
    end

    munge do |value|
      if value.is_a?(String)
        value.upcase
      else
        value
      end
    end

    newvalues('ROUND_ROBIN', 'LEAST_CONNECTIONS')
  end

  newproperty(:health_check_path) do
    desc 'The URL to call for health cheking.'
    validate do |value|
      raise('The health check path must be a string.') unless value.is_a?(String)
    end
  end

  newproperty(:health_check_parse) do
    desc 'A regular expression for the health check.'
    validate do |value|
      raise('The health check regex must be a string.') unless value.is_a?(String)
    end
  end
  
  newproperty(:server_ips, array_matching: :all) do
    desc 'The servers/IPs attached to the load balancer.'

    def insync?(is)
      if is.is_a? Array
        return is.sort == should.sort
      else
        return is == should
      end
    end
  end
end
