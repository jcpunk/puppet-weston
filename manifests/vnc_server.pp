# @summary Setup weston VNC sessions
#
# @param vnc_min_port
#   What is the lowest VNC port we want to allow
# @param manage_vnc_start_script
#   Do we manage the start script?
# @param manage_vnc_options_file
#   Do we manage the vnc options file?
# @param manage_vnc_users_file
#   Do we manage the vnc users file?
# @param manage_vnc_polkit_file
#   Do we manage the vnc polkit file?
#
# @param vnc_start_script
#   The script that starts weston in VNC mode
# @param vnc_options_file
#   An environment file you can use to inject options
# @param vnc_server_options
#   Extra options to set on the VNC server (ie ['--address=::1', '--disable-transport-layer-security'])
# @param vnc_users_file
#   A list of which users are using which VNC ports
#
# @param vnc_start_script_mode
#   This should have world exec as it runs as your VNC user
# @param vnc_options_file_mode
#   This should have world read so your VNC user can look at it
# @param vnc_users_file_mode
#   This should have world read so your VNC user can look at it
#
# @param manage_vnc_services
#   Should this module manage the VNC server services
# @param default_vnc_service_ensure
#   What should the VNC service ensure be by default?
#   NULL works for "no preference"
# @param default_vnc_service_enable
#   What should the VNC service enable be by default?
#   NULL works for "no preference"
#
# @param manage_systemd_unit_file
#   Should this module setup the systemd template unit
# @param systemd_template_startswith
#   What is the 'unit name' of the service
# @param systemd_template_endswith
#   This should always be `.service` unless you're up to something weird
#
# @param manage_systemd_user_unit_file
#   Should this module setup the systemd user template unit
# @param systemd_user_template_startswith
#   What is the 'unit name' of the user service
# @param systemd_user_template_endswith
#   This should always be `.service` unless you're up to something weird
#
# @param vnc_polkit_file
#   A policy kit file you can use to let users restart their own sessions via systemctl --system
# @param vnc_polkit_file_mode
#   This should have world read so unpriviledged polkit can check it
# @param default_user_can_control_service
#   Should this module configure polkit so the VNC user can control the system service by default?
# @param default_extra_users_can_control_service
#   Extra users who will automatically be granted polkit rights to the system service by default
#
# @param vnc_sessions
#   A hash of VNC servers to setup  Format:
#   weston::vnc_server::vnc_sessions:
#     userA:
#       comment: Sometimes you've gotta write it down
#       displaynumber: 1
#       ensure: running
#       enable: true
#       user_can_control_service: true
#       extra_users_can_control_service:
#         - userB
#     userB:
#       displaynumber: 5902
#       ensure: NULL
#       enable: false
#       user_can_control_service: false
#
class weston::vnc_server (
  Integer[1,65535] $vnc_min_port = 5900,
  Boolean $manage_vnc_start_script = true,
  Stdlib::Absolutepath $vnc_start_script = '/usr/libexec/weston-vnc',
  String $vnc_start_script_mode = '0755',
  Boolean $manage_vnc_options_file = true,
  Stdlib::Absolutepath $vnc_options_file = '/etc/xdg/weston/vncserver.opts',
  String $vnc_options_file_mode = '0644',
  Array[String[1]] $vnc_server_options = [],
  Boolean $manage_vnc_users_file = true,
  Stdlib::Absolutepath $vnc_users_file = '/etc/xdg/weston/vncserver.users',
  String $vnc_users_file_mode = '0644',

  Boolean $manage_systemd_unit_file = true,
  String $systemd_template_startswith = 'weston-vncserver',
  String $systemd_template_endswith = '.service',

  Boolean $manage_systemd_user_unit_file = true,
  String $systemd_user_template_startswith = 'weston-user-vncserver',
  String $systemd_user_template_endswith = '.service',

  Boolean $manage_vnc_services = true,
  Optional[Enum['running', 'stopped']] $default_vnc_service_ensure = undef,
  Optional[Boolean] $default_vnc_service_enable = undef,

  Boolean $manage_vnc_polkit_file = true,
  Stdlib::Absolutepath $vnc_polkit_file = '/etc/polkit-1/rules.d/25-puppet-weston-vnc_server.rules',
  String $vnc_polkit_file_mode = '0644',
  Boolean $default_user_can_control_service = false,
  Array[String[1]] $default_extra_users_can_control_service = [],

  Hash[String, Hash[Enum['displaynumber', 'user_can_control_service', 'comment', 'ensure', 'enable', 'extra_users_can_control_service'], Variant[Array[String], String, Integer, Boolean, Undef]]] $vnc_sessions = {},
) inherits weston {
  if $manage_vnc_start_script {
    file { $vnc_start_script:
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => $vnc_start_script_mode,
      content => epp('weston/usr/libexec/weston-vnc.epp', { 'vnc_min_port' => $vnc_min_port }),
    }
  }

  if $manage_vnc_options_file {
    file { $vnc_options_file:
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => $vnc_options_file_mode,
      content => epp('weston/etc/xdg/weston/vncserver.opts.epp', { 'options' => $vnc_server_options }),
    }
  }

  if $manage_systemd_unit_file {
    systemd::manage_unit { 'system weston vnc unit':
      ensure        => 'present',
      name          => "${systemd_template_startswith}@${systemd_template_endswith}",
      unit_entry    => {
        'Description' => 'Remote desktop service (VNC) with Weston',
        'After'       => ['syslog.target', 'network.target', 'systemd-user-sessions.service', 'remote-fs.target'],
      },
      service_entry => {
        'Type'           => 'notify',
        'User'           => '%I',
        'Environment'    => 'XDG_SESSION_TYPE=wayland',
        'ExecStart'      => $vnc_start_script,
        'StandardOutput' => 'journal',
        'StandardError'  => 'journal',
      },
      install_entry => {
        'WantedBy' => 'multi-user.target',
      },
    }
  }
  if $manage_systemd_user_unit_file {
    systemd::manage_unit { 'user weston vnc unit':
      ensure        => 'present',
      name          => "${systemd_user_template_startswith}@${systemd_user_template_endswith}",
      path          => '/etc/systemd/user',
      unit_entry    => {
        'Description' => 'Remote desktop service (VNC) with Weston',
      },
      service_entry => {
        'Type'           => 'notify',
        'PAMName'        => 'login',
        'Environment'    => 'XDG_SESSION_TYPE=wayland',
        'ExecStart'      => "${vnc_start_script} --port %I",
        'StandardOutput' => 'journal',
        'StandardError'  => 'journal',
      },
      install_entry => {
        'WantedBy' => 'default.target',
      },
    }
  }

  if $manage_vnc_users_file {
    concat { $vnc_users_file:
      owner => 'root',
      group => 'root',
      mode  => $vnc_users_file_mode,
    }
    concat::fragment { 'vnc user file header':
      target  => $vnc_users_file,
      content => "#\n# THIS FILE IS MANAGED BY PUPPET\n#\n\n",
      order   => '01',
    }

    $vnc_sessions.keys.sort.each |$username| {
      unless 'displaynumber' in $vnc_sessions[$username] {
        fail("You must set the 'displaynumber' property for ${username}'s vnc server")
      }
      if 'comment' in $vnc_sessions[$username] {
        $comment = $vnc_sessions[$username]['comment']
      } else {
        $comment = ''
      }

      if 'user_can_control_service' in $vnc_sessions[$username] {
        $user_can_control_service = $vnc_sessions[$username]['user_can_control_service']
      } else {
        $user_can_control_service = $default_user_can_control_service
      }

      if $manage_vnc_polkit_file {
        if $user_can_control_service {
          if 'extra_users_can_control_service' in $vnc_sessions[$username] {
            $extra_users_to_grant = sort(unique(flatten([$default_extra_users_can_control_service, $vnc_sessions[$username]['extra_users_can_control_service']])))
          } else {
            $extra_users_to_grant = sort(unique(flatten([$default_extra_users_can_control_service])))
          }
        } else {
          $extra_users_to_grant = []
        }
      } else {
        $extra_users_to_grant = 'polkit rules for vnc disabled in puppet'
      }

      if $vnc_sessions[$username]['displaynumber'] < $vnc_min_port {
        $real_displaynumber = $vnc_sessions[$username]['displaynumber'] + $vnc_min_port
      } else {
        $real_displaynumber = $vnc_sessions[$username]['displaynumber']
      }

      concat::fragment { "vnc user ${username}":
        target  => $vnc_users_file,
        content => "# ${comment}\n# non-root users who can control service for ${username}: ${extra_users_to_grant}\n:${real_displaynumber}=${username}\n",
      }
    }
  }

  if $manage_vnc_services {
    $vnc_sessions.keys.sort.each |$username| {
      if 'ensure' in $vnc_sessions[$username] {
        $user_vnc_ensure = $vnc_sessions[$username]['ensure']
      } else {
        $user_vnc_ensure = $default_vnc_service_ensure
      }

      if 'enable' in $vnc_sessions[$username] {
        $user_vnc_enable = $vnc_sessions[$username]['enable']
      } else {
        $user_vnc_enable = $default_vnc_service_enable
      }

      if $manage_vnc_start_script and $manage_vnc_options_file {
        service { "${systemd_template_startswith}@${username}${systemd_template_endswith}":
          ensure    => $user_vnc_ensure,
          enable    => $user_vnc_enable,
          subscribe => [File[$vnc_start_script], File[$vnc_options_file]],
        }
      } elsif $manage_vnc_start_script {
        service { "${systemd_template_startswith}@${username}${systemd_template_endswith}":
          ensure    => $user_vnc_ensure,
          enable    => $user_vnc_enable,
          subscribe => File[$vnc_start_script],
        }
      } elsif $manage_vnc_options_file {
        service { "${systemd_template_startswith}@${username}${systemd_template_endswith}":
          ensure    => $user_vnc_ensure,
          enable    => $user_vnc_enable,
          subscribe => File[$vnc_options_file],
        }
      } else {
        service { "${systemd_template_startswith}@${username}${systemd_template_endswith}":
          ensure => $user_vnc_ensure,
          enable => $user_vnc_enable,
        }
      }
    }
  }

  if $manage_vnc_polkit_file {
    concat { $vnc_polkit_file:
      owner => 'root',
      group => 'root',
      mode  => $vnc_polkit_file_mode,
    }

    concat::fragment { 'polkit_header':
      target  => $vnc_polkit_file,
      content => "/* THIS FILE IS MANAGED BY PUPPET */\n",
      order   => '01',
    }

    $vnc_sessions.keys.sort.each |$username| {
      if 'user_can_control_service' in $vnc_sessions[$username] {
        $user_can_control_service = $vnc_sessions[$username]['user_can_control_service']
      } else {
        $user_can_control_service = $default_user_can_control_service
      }

      if $user_can_control_service {
        if 'extra_users_can_control_service' in $vnc_sessions[$username] {
          $extra_users_to_grant = sort(unique(flatten([$default_extra_users_can_control_service, $vnc_sessions[$username]['extra_users_can_control_service'], $username])))
        } else {
          $extra_users_to_grant = sort(unique(flatten([$default_extra_users_can_control_service, $username])))
        }

        concat::fragment { "polkit entry for ${username} vnc service":
          target  => $vnc_polkit_file,
          order   => 20,
          content => epp('weston/etc/polkit-1/rules.d/25-puppet-weston-vnc_server.rules.epp', { 'systemd_template_startswith' => $systemd_template_startswith, 'systemd_template_endswith' => $systemd_template_endswith, 'usernames' => $extra_users_to_grant }),
        }
      }
    }
  }
}
