# Author::    Liam Bennett  (mailto:lbennett@opentable.com)
# Copyright:: Copyright (c) 2013 OpenTable Inc
# License::   MIT

# == Class: kafka::mirror::service
#
# This private class is meant to be called from `kafka::mirror`.
# It manages the kafka-mirror service
#
class kafka::mirror::service(
  String $user                               = $kafka::mirror::user,
  String $group                              = $kafka::mirror::group,
  Stdlib::Absolutepath $config_dir           = $kafka::mirror::config_dir,
  Stdlib::Absolutepath $log_dir              = $kafka::mirror::log_dir,
  Stdlib::Absolutepath $bin_dir              = $kafka::mirror::bin_dir,
  String $service_name                       = $kafka::mirror::service_name,
  Boolean $service_install                   = $kafka::mirror::service_install,
  Enum['running', 'stopped'] $service_ensure = $kafka::mirror::service_ensure,
  Boolean $service_requires_zookeeper        = $kafka::mirror::service_requires_zookeeper,
  Integer $limit_nofile                      = $kafka::mirror::limit_nofile,
  Hash $env                                  = $kafka::mirror::env,
  Hash $consumer_config                      = $kafka::mirror::consumer_config,
  Hash $producer_config                      = $kafka::mirror::producer_config,
  Hash $service_config                       = $kafka::mirror::service_config,
  $mirror_jmx_opts                           = $kafka::mirror::mirror_jmx_opts,
  $mirror_log4j_opts                         = $kafka::mirror::mirror_log4j_opts,
  $mirror_heap_opts                          = $kafka::mirror::mirror_heap_opts,
) {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $service_install {
    $env_defaults = {
      'KAFKA_JMX_OPTS'   => $mirror_jmx_opts,
      'KAFKA_LOG4J_OPTS' => $mirror_log4j_opts,
      'KAFKA_HEAP_OPTS'  => $mirror_heap_opts,
    }
    $environment = deep_merge($env_defaults, $env)

    if $::service_provider == 'systemd' {
      include ::systemd

      file { "/etc/systemd/system/${service_name}.service":
        ensure  => file,
        mode    => '0644',
        content => template('kafka/unit.erb'),
      }

      file { "/etc/init.d/${service_name}":
        ensure => absent,
      }

      File["/etc/systemd/system/${service_name}.service"]
      ~> Exec['systemctl-daemon-reload']
      -> Service[$service_name]

    } else {
      file { "/etc/init.d/${service_name}":
        ensure  => file,
        mode    => '0755',
        content => template('kafka/init.erb'),
        before  => Service[$service_name],
      }
    }

    service { $service_name:
      ensure     => $service_ensure,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }
  }
}
