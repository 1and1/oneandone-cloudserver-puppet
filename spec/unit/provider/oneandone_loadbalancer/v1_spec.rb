require 'spec_helper'

provider_type = Puppet::Type.type(:oneandone_loadbalancer).provide(:v1)

ENV['ONEANDONE_API_KEY'] = 'apihashkey'

describe provider_type do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:oneandone_loadbalancer).new(
        name: ' test-loadbalancer1',
        method: 'ROUND_ROBIN',
        rules: [
          {
            protocol: 'TCP',
            port_balancer: 80,
            port_server: 80,
            source: '0.0.0.0'
          }
        ]
      )
      @provider = provider_type.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Oneandone_loadbalancer::ProviderV1
    end

    it 'should have 1 rule' do
      expect(@resource['rules'].length).to eq 1
    end

    it 'should have correct method' do
      expect(@resource['method']).to eq 'ROUND_ROBIN'
    end
  end
  
  context 'with custom configuration' do
    before(:all) do
      @resource = Puppet::Type.type(:oneandone_loadbalancer).new(
        name: ' test-loadbalancer2',
        description: 'lb desc',
        datacenter: 'GB',
        method: 'LEAST_CONNECTIONS',
        health_check_test: 'TCP',
        health_check_interval: 15,
        persistence: true,
        persistence_time: 1200,
        rules: [
          {
            port_balancer: 80,
            port_server: 80,
            protocol: 'TCP',
            source: '0.0.0.0'
          },
          {
            port_balancer: 8080,
            port_server: 8080,
            protocol: 'TCP',
            source: '0.0.0.0'
          },
          {
            port_balancer: 161,
            port_server: 162,
            protocol: 'UDP',
            source: '0.0.0.0'
          }
        ],
        server_ips: ['99.228.55.231', '81.189.100.11']
      )
      @provider = provider_type.new(@resource)
    end
    
    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Oneandone_loadbalancer::ProviderV1
    end
    
    it 'should have correct description' do
      expect(@resource['description']).to eq 'lb desc'
    end

    it 'should be in correct data center' do
      expect(@resource['datacenter']).to eq 'GB'
    end

    it 'should have correct health check interval' do
      expect(@resource['health_check_interval']).to eq 15
    end

    it 'should have persistence enabled' do
      expect(@resource['persistence']).to eq :true
    end

    it 'should have correct persistence time' do
      expect(@resource['persistence_time']).to eq 1200
    end

    it 'should have correct health check test' do
      expect(@resource['health_check_test']).to eq :TCP
    end

     it 'should have correct method' do
      expect(@resource['method']).to eq 'LEAST_CONNECTIONS'
    end
    
    it 'should have 3 rule' do
      expect(@resource['rules'].length).to eq 3
    end
    
    it 'should have 2 server/IP assigned' do
      expect(@resource['server_ips'].length).to eq 2
    end
  end
end
