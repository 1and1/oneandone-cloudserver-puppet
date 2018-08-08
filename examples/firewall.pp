oneandone_firewall { 'puppet-test-policy':
  ensure      => present,
  description => 'Test policy desc',
  rules       => [
    {
      port => '80-83',
      protocol  => 'TCP',
      description => 'Testing firewall improvements with puppet.',
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
