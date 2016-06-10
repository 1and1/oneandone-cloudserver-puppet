require 'spec_helper'

provider_type = Puppet::Type.type(:oneandone_server).provide(:v1)

ENV['ONEANDONE_API_KEY'] = 'apihashkey'

describe provider_type do
  context 'with the minimum params' do
    before(:all) do
      @resource = Puppet::Type.type(:oneandone_server).new(
        name: ' test-server1',
        appliance_id: 'SDF86S5SD866F5SDF86SFSD8FSD8',
        server_size: 'M'
      )
      @provider = provider_type.new(@resource)
    end

    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Oneandone_server::ProviderV1
    end
    
    it 'should expose server_size as M' do
      expect(@resource['server_size']).to eq 'M'
    end
  end
  
  context 'with flex configuration' do
    before(:all) do
      @resource = Puppet::Type.type(:oneandone_server).new(
        name: ' test-server2',
        appliance_id: 'ABCDEF373234234234234',
        datacenter: 'ES',
        ram: 0.5,
        virtual_processors: 1,
        cores_per_processor: 1,
        hdds: [
          {
            size: 40,
            is_main: true
          },
          {
            size: 20,
            is_main: false
          }
        ]
      )
      @provider = provider_type.new(@resource)
    end
    
    it 'should be an instance of the ProviderV1' do
      expect(@provider).to be_an_instance_of Puppet::Type::Oneandone_server::ProviderV1
    end
    
    it 'should expose server_size as FLEX' do
      expect(@resource['server_size']).to eq 'FLEX'
    end
    
    it 'should expose datacenter as ES' do
      expect(@resource['datacenter']).to eq 'ES'
    end
    
    it 'should expose RAM as 0.5' do
      expect(@resource['ram']).to eq 0.5
    end
    
    it 'should expose virtual_processors as 1' do
      expect(@resource['virtual_processors']).to eq 1
    end
    
    it 'should expose cores_per_processor as 1' do
      expect(@resource['cores_per_processor']).to eq 1
    end
    
    it 'should expose 2 HDDs' do
      expect(@resource['hdds'].length).to eq 2
    end
  end
end
