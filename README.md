# 1&amp;1 Cloud Server Puppet

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Installation](#installation)
1. [Usage](#usage)
    * [Full Server Example](#full-server-example)
1. [Reference](#reference)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

The 1&amp;1 Puppet module leverages deployment of 1&amp;1 Cloud servers from a Puppet manifest file and command-line interface.

The 1&amp;1 Puppet module relies on the 1&amp;1 Cloud API to manage 1&amp;1 servers. A Puppet manifest file can be used to describe a desired infrastructure including servers, data center locations for the servers, CPU units,  virtual cores, memory, states and other properties. The infrastructure deployment can then be easily automated using Puppet.

## Requirements

* Puppet 4.x
* Ruby 2.x
* 1&amp;1 Ruby SDK (1and1)
* 1&amp;1 account

## Installation

1. Install the 1&amp;1 Ruby SDK gem.

    `gem install 1and1`

2. Install the module.

    `puppet module install oneandone-puppet1and1`

3. Set the environment variable for authentication.

    `export ONEANDONE_API_KEY="your-token-key-here"`

## Usage

Puppet has ability to manage the state of complex systems using a simple resource model. For that purpose, Puppet provides a declarative language or Domain Specific Language (DSL). Puppet manifest files contain the model described in DSL. This snippet describes a simple 1&amp;1 server resource.

```
oneandone_server { 'example-server':
  ensure       => present,
  appliance_id => 'FF696FFE6FB96FC54638DB47E9321E25',
  server_size  => 'L'
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

## Limitations

Currently the module only manages the `oneandone_server` resources.

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

