require 'spec_helper'

provider_type = Puppet::Type.type(:oneandone_firewall).provide(:v1)

ENV['ONEANDONE_API_KEY'] = 'apihashkey'

describe provider_type do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:oneandone_firewall).new(
        name: ' test-firewall1',
        rules: [
          {
            protocol: 'ICMP'
          }
        ]
      )
      @provider = provider_type.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Oneandone_firewall::ProviderV1
    end

    it 'should have 1 rule' do
      expect(@resource['rules'].length).to eq 1
    end
  end
  
  context 'with flex configuration' do
    before(:all) do
      @resource = Puppet::Type.type(:oneandone_firewall).new(
        name: ' test-firewall2',
        description: 'test policy description',
        rules: [
          {
            port_from: 80,
            port_to: 80,
            protocol: 'TCP',
            source: '0.0.0.0'
          },
          {
            port_from: 8080,
            port_to: 8080,
            protocol: 'TCP/UDP',
            source: '0.0.0.0'
          },
          {
            port_from: 161,
            port_to: 162,
            protocol: 'UDP',
            source: '0.0.0.0'
          },
          {
            protocol: 'ICMP'
          },
          {
            protocol: 'GRE'
          },
          {
            protocol: 'IPSEC'
          }
        ],
        server_ips: ['110.124.35.221', '81.189.100.11']
      )
      @provider = provider_type.new(@resource)
    end
    
    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Oneandone_firewall::ProviderV1
    end
    
    it 'should have correct description' do
      expect(@resource['description']).to eq 'test policy description'
    end
    
    it 'should have 6 rule' do
      expect(@resource['rules'].length).to eq 6
    end
    
    it 'should have 2 IPs assigned' do
      expect(@resource['server_ips'].length).to eq 2
    end
  end
end
