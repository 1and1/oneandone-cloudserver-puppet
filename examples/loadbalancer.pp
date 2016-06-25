oneandone_loadbalancer { 'puppet-load-balancer1':
  ensure                => present,
  method                => 'LEAST_CONNECTIONS',
  rules                 => [
    {
      protocol      => 'TCP',
      port_balancer => 80,
      port_server   => 80,
      source        => '0.0.0.0'
    }
  ]
}
