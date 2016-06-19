require 'spec_helper'

firewall_type = Puppet::Type.type(:oneandone_firewall)

describe firewall_type do
  let :params do
    [
      :name
    ]
  end

  let :properties do
    [
      :ensure,
      :id,
      :description,
      :rules,
      :server_ips
    ]
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(firewall_type.parameters).to be_include(param)
    end
  end
  
  it 'should have expected properties' do
    properties.each do |property|
      expect(firewall_type.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should require a name' do
    expect do
      firewall_type.new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end
  
  it 'should support :present as a value to :ensure' do
    firewall_type.new(:name => 'test', :ensure => :present)
  end

  it 'should support :absent as a value to :ensure' do
    firewall_type.new(:name => 'test', :ensure => :absent)
  end
end
