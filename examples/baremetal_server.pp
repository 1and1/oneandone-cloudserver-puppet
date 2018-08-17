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

$datacenter         = 'GB'
$appliance_id       = '33352CCE1E710AF200CD1234BFD18862' # CENTOS 6 MINIMAL SYSTEM (64BIT)
$baremetal_model_id = '81504C620D98BCEBAA5202D145203B4B' # BMC_L
$server_type        = 'baremetal'

oneandone_server { '1node-baremetal-example':
  ensure              => present,
  datacenter          => $datacenter,
  appliance_id        => $appliance_id,
  baremetal_model_id  => $baremetal_model_id,
  server_type         => $server_type
}
