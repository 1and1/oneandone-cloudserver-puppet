
Puppet::Type.newtype(:oneandone_firewall) do
  @doc = 'Type representing a 1&1 firewall policy.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the firewall policy.'
    validate do |value|
      raise('The name should be a String.') unless value.is_a?(String)
    end
  end

  newproperty(:rules, array_matching: :all) do
    desc 'The firewall policy rules.'
  end
  
  newproperty(:id) do
    desc 'The firewall policy ID.'
  end

  newproperty(:description) do
    desc 'The firewall policy description.'
  end
  
  newproperty(:server_ips, array_matching: :all) do
    desc 'The servers/IPs attached to the firewall policy.'

    def insync?(is)
      if is.is_a? Array
        return is.sort == should.sort
      else
        return is == should
      end
    end
  end
end
