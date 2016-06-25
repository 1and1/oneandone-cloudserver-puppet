require 'spec_helper'

loadbalancer_type = Puppet::Type.type(:oneandone_loadbalancer)

describe loadbalancer_type do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :ensure,
      :datacenter,
      :description,
      :health_check_interval,
      :health_check_parse,
      :health_check_path,
      :health_check_test,
      :id,
      :method,
      :persistence,
      :persistence_time,
      :rules,
      :server_ips
    ]
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(loadbalancer_type.parameters).to be_include(param)
    end
  end
  
  it 'should have expected properties' do
    properties.each do |property|
      expect(loadbalancer_type.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should require a name' do
    expect do
      loadbalancer_type.new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  
  it 'should support :present as a value to :ensure' do
    loadbalancer_type.new(:name => 'test', :ensure => :present)
  end

  it 'should support :absent as a value to :ensure' do
    loadbalancer_type.new(:name => 'test', :ensure => :absent)
  end

  it 'should default datacenter to US' do
    lb = loadbalancer_type.new(:name => 'lb-test')
    expect(lb[:datacenter]).to eq('US')
  end

  it 'should default persistence to false' do
    lb = loadbalancer_type.new(:name => 'lb-test')
    expect(lb[:persistence]).to eq(:false)
  end

  it 'should default health_check_test to NONE' do
    lb = loadbalancer_type.new(:name => 'lb-test')
    expect(lb[:health_check_test]).to eq(:NONE)
  end
end
