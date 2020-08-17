# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
# Setup for Filebeat-oss
class wazuh::filebeat-oss (
  $filebeat_oss_elasticsearch_ip = 'localhost',
  $filebeat_oss_elasticsearch_port = '9200',
  $elasticsearch_server_ip = "\"${filebeat_oss_elasticsearch_ip}:${filebeat_oss_elasticsearch_port}\"",

  $filebeat_oss_package = 'filebeat-oss',
  $filebeat_oss_service = 'filebeat',
  $filebeat_oss_version = '7.8.0',
  $wazuh_app_version = '3.13.1_7.8.0',
  $wazuh_extensions_version = 'v3.13.1',
  $wazuh_filebeat_module = 'wazuh-filebeat-0.1.tar.gz',
){

  class {'wazuh::repo_elastic':}

  if $::osfamily == 'Debian' {
    Class['wazuh::repo_elastic'] -> Class['apt::update'] -> Package[$filebeat_oss_package]
  } else {
    Class['wazuh::repo_elastic'] -> Package[$filebeat_oss_package]
  }

  package { 'filebeat':
    ensure => $filebeat_oss_version,
    name   => $filebeat_oss_package,
  }

  file { 'Configure filebeat.yml':
    owner   => 'root',
    path    => '/etc/filebeat/filebeat.yml',
    group   => 'root',
    mode    => '0644',
    notify  => Service[$filebeat_service], ## Restarts the service
    content => template('wazuh/filebeat_yml.erb'),
    require => Package[$filebeat_oss_package]
  }

  exec { 'Installing wazuh-template.json...':
    path    => '/usr/bin',
    command => "curl -so /etc/filebeat/wazuh-template.json 'https://raw.githubusercontent.com/wazuh/wazuh/${wazuh_extensions_version}/extensions/elasticsearch/7.x/wazuh-template.json'",
    notify  => Service[$filebeat_oss_service],
    require => Package[$filebeat_oss_package]
  }

  exec { 'Installing filebeat module ... Downloading package':
    path    => '/usr/bin',
    command => "curl -o /root/${$wazuh_filebeat_module} https://packages.wazuh.com/3.x/filebeat/${$wazuh_filebeat_module}",
  }

  exec { 'Unpackaging ...':
    command => '/bin/tar -xzvf /root/wazuh-filebeat-0.1.tar.gz -C /usr/share/filebeat/module',
    notify  => Service[$filebeat_oss_service],
    require => Package[$filebeat_oss_package]
  }

  file { '/usr/share/filebeat/module/wazuh':
    ensure  => 'directory',
    mode    => '0755',
    require => Package[$filebeat_oss_package]
  }

  service { 'filebeat':
    ensure  => running,
    enable  => true,
    require => Package[$filebeat_oss_package]
  }
}