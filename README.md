# 1&amp;1 Cloud Server Puppet

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Installation](#installation)
1. [Usage](#usage)
    * [Full Server Example](#full-server-example)
    * [Firewall Example](#firewall-example)
    * [Load Balancer Example](#load-balancer-example)
1. [Reference](#reference)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

The 1&amp;1 Puppet module leverages deployment of 1&amp;1 Cloud servers from a Puppet manifest file and command-line interface.

The 1&amp;1 Puppet module relies on the 1&amp;1 Cloud API to manage 1&amp;1 servers. A Puppet manifest file can be used to describe a desired infrastructure including servers, data center locations for the servers, CPU units,  virtual cores, memory, states and other properties. The infrastructure deployment can then be easily automated using Puppet.

For more information on the 1&amp;1 Cloud Server Puppet module see the [1&1 Community Portal](https://www.1and1.com/cloud-community/).

## Requirements

* Puppet 4.x
* Ruby 2.x
* 1&amp;1 Ruby SDK (1and1)
* 1&amp;1 account

## Installation

1. Install the 1&amp;1 Ruby SDK gem.

    ```
    gem install 1and1
    ```

2. Install the module.

    ```
    puppet module install oneandone-puppet1and1
    ```

3. Set the environment variable for authentication.

    ```
    export ONEANDONE_API_KEY="your-token-key-here"
    ```

## Usage

Puppet has ability to manage the state of complex systems using a simple resource model. For that purpose, Puppet provides a declarative language or Domain Specific Language (DSL). Puppet manifest files contain the model described in DSL. This snippet describes a simple 1&amp;1 server resource.

```
oneandone_server { 'example-server':
  ensure       => present,
  appliance_id => 'FF696FFE6FB96FC54638DB47E9321E25',
  server_size  => 'L'
}
```

The following snippet describes a simple 1&amp;1 baremetal server resource:
```
oneandone_server { '1node-baremetal-example':
  ensure              => present,
  datacenter          => 'GB',
  appliance_id        => '33352CCE1E710AF200CD1234BFD18862',
  baremetal_model_id  => '81504C620D98BCEBAA5202D145203B4B'
}
```

Applying a Puppet manifest which contains the snippet above will create a 1&amp;1 server named `example-server` in the `US` data center (default) using the Debian 8 appliance image with fixed-server size 'L'.

```
puppet apply my-manifest-file.pp
```

Puppet also provides a way to check on existing resources of a certain type. The following command will list all existing 1&amp;1 servers available to the user.

```
puppet resource oneandone_server
```

Displayng a single server, `example-server` for an instance, is simple as well.

```
puppet resource oneandone_server example-server
```

### Full Server Example

The following example describes a full server in a flex configuration which utilizes an existing public IP, with a load balancer, a firewall policy, and more.

```
oneandone_server { 'example2':
  ensure               => stopped,
  description          => 'example server 2',
  password             => 'My-Server-Pass-Here',
  rsa_key              => 'my-rsa-key-here',
  ip_address           => '62.151.182.163',
  datacenter           => 'DE',
  appliance_id         => '72A90ECC29F718404AC3093A3D78327C',
  firewall_id          => '34A7E423DA3253E6D38563ED06F1041F',
  load_balancer_id     => '1D7E79BF6548D36B26C8ED7E4304F99C',
  monitoring_policy_id => '6027B730256C9585B269DAA8B1788DEC',
  ram                  => 2,
  virtual_processors   => 1,
  cores_per_processor  => 1,
  hdds                 => [
    {
      size    => 40,
      is_main => true
    },
    {
      size    => 20,
      is_main => false
    }
  ]
}
```

### Firewall Example

The next example shows how to create a firewall policy with a couple of rules and assign server IPs to the policy.

```
oneandone_firewall { 'puppet-test-policy':
  ensure      => present,
  description => 'Firewall description',
  rules       => [
    {
      port_from => 80,
      port_to   => 80,
      protocol  => 'TCP',
      source    => '0.0.0.0'
    },
    {
      port_from => 8080,
      port_to   => 8080,
      protocol  => 'TCP/UDP',
      source    => '0.0.0.0'
    },
    {
      port_from => 161,
      port_to   => 162,
      protocol  => 'UDP',
      source    => '0.0.0.0'
    },
    {
      protocol  => 'ICMP'
    },
    {
      protocol  => 'GRE'
    },
    {
      protocol  => 'IPSEC'
    }
  ],
  server_ips    => ['109.228.55.231', '82.165.163.238', '109.228.59.190']
}
```

### Load Balancer Example

The module supports 1&amp;1 load balancers as well. 

```
oneandone_loadbalancer { 'puppet-load-balancer':
  ensure                => present,
  description           => 'load balancer desc',
  datacenter            => 'GB',
  method                => 'LEAST_CONNECTIONS',
  health_check_test     => 'TCP',
  health_check_interval => 15,
  persistence           => true,
  persistence_time      => 1200,
  rules                 => [
    {
      protocol      => 'TCP',
      port_balancer => 80,
      port_server   => 80,
      source        => '0.0.0.0'
    },
    {
      protocol      => 'UDP',
      port_balancer => 161,
      port_server   => 161,
      source        => '0.0.0.0'
    }
  ]
}

```

## Reference

**Describe `oneandone_server` type, properties and the provider:**

```
puppet describe oneandone_server
```

**Remove server resources:**

```
oneandone_server { ['server1', 'server2']: 
  ensure => absent
}
```

A full command statement to remove a server and keep its IP addresses is as follows.

```
puppet apply -e 'oneandone_server {"node1": ensure => absent, keep_ips => true}'
```

**Start a server resource:**

```
oneandone_server {'server1':
  ensure => running
}
```
or
```
oneandone_server {'server1':
  ensure => present
}
```

**Stop a server resource:**

```
oneandone_server {'server1':
  ensure => stopped
}
```

To force a server shutdown set `force_stop` to true.

```
oneandone_server {'server1':
  ensure     => stopped,
  force_stop => true
}
```

**Create a firewall policy:**

```
oneandone_firewall { 'fpolicy1':
  ensure      => present,
  rules       => [
    {
      port_from => 80,
      port_to   => 80,
      protocol  => 'TCP'
    }
  ]
}
```

**Update the description and server IPs of an existing firewall policy:**

```
oneandone_firewall { 'fpolicy1':
  description => 'new description',
  server_ips    => ['109.228.55.231']
}
```

Specify `server_ips => []` to unassign all server IPs from the policy.

**Create a load balancer:**

```
oneandone_loadbalancer { 'load-balancer-example':
  ensure                => present,
  method                => 'ROUND_ROBIN',
  rules                 => [
    {
      protocol      => 'TCP',
      port_balancer => 80,
      port_server   => 80,
      source        => '0.0.0.0'
    }
  ]
}
```

Set the load balancer properties, such as `method`, `persistence`, `rules` etc., by adding or editing them in the manifest file.
Check the available properties for the load balancer type with:

```
puppet describe oneandone_loadbalancer
```

## Limitations

- The module only manages the `oneandone_server`, `oneandone_firewall` and `oneandone_loadbalancer` resources.
- Not all the API operations on the resources are supported.
- The module does not support the firewall rules update.
- Due to 1&amp;1 API limitations, it is not allowed to modify all load balancer rules at once.

## Development

1. Fork the repository (`https://github.com/[my-github-username]/oneandone-cloudserver-puppet/fork`).
2. Create a new feature branch (`git checkout -b my-new-feature`).
3. Commit the changes (`git commit -am 'New feature description'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new pull request.

[Rake](https://rubygems.org/gems/rake) is recommended for building the module for testing, deployment, and style check before creating a pull request.

```
rake build
```

```
rake test
```

```
rake rubocop
```

