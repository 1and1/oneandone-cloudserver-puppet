# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# https://docs.puppet.com/guides/tests_smoke.html
#

$datacenter    = 'GB'
$appliance_id  = 'FF696FFE6FB96FC54638DB47E9321E25' # debian8-64min
$server_size    = 'L'

oneandone_server { 'node1-example':
  ensure       => present,
  datacenter   => $datacenter,
  appliance_id => $appliance_id,
  server_size  => $server_size,
}

oneandone_server { 'node2-example':
  ensure              => stopped,
  datacenter          => 'DE',
  appliance_id        => $appliance_id,
  ram                 => 2,
  virtual_processors  => 1,
  cores_per_processor => 1,
  hdds                => [
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
