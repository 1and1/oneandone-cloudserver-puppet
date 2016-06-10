require 'spec_helper'

server_type = Puppet::Type.type(:oneandone_server)

describe server_type do
  let :params do
    [
      :name,
      :keep_ips,
      :force_stop,
      :ip_address
    ]
  end

  let :properties do
    [
      :ensure,
      :ram,
      :virtual_processors,
      :cores_per_processor,
      :datacenter,
      :id,
      :description,
      :password,
      :rsa_key,
      :firewall_id,
      :load_balancer_id,
      :monitoring_policy_id,
      :ips,
      :hdds,
      :image,
      :appliance_id,
      :server_size
    ]
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(server_type.parameters).to be_include(param)
    end
  end
  
  it 'should have expected properties' do
    properties.each do |property|
      expect(server_type.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should require a name' do
    expect do
      server_type.new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  
  it 'should support :present as a value to :ensure' do
    server_type.new(:name => 'test', :ensure => :present)
  end

  it 'should support :absent as a value to :ensure' do
    server_type.new(:name => 'test', :ensure => :absent)
  end

  it 'should support :running as a value to :ensure' do
    server_type.new(:name => 'test', :ensure => :running)
  end

  it 'should support :stopped as a value to :ensure' do
    server_type.new(:name => 'test', :ensure => :stopped)
  end
  
  it 'should default datacenter to US' do
    server = server_type.new(:name => 'test')
    expect(server[:datacenter]).to eq('US')
  end

  it 'should default keep_ips to false' do
    server = server_type.new(:name => 'test')
    expect(server[:keep_ips]).to eq(:false)
  end

  it 'should default force_stop to false' do
    server = server_type.new(:name => 'test')
    expect(server[:force_stop]).to eq(:false)
  end
  
  it 'should default server_size to FLEX' do
    server = server_type.new(:name => 'test')
    expect(server[:server_size]).to eq('FLEX')
  end
end
