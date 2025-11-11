# @summary Install the weston desktop
#
# Simply install the weston desktop
#
# @param manage_packages
#   Should this module even care about the packages?
# @param package_names
#   Packages to install
# @param packages_ensure
#   What to ensure for the packages
#
# @param manage_weston_ini_dir
#   Should we create the containing directory for weston.ini?
# @param manage_weston_ini
#   Should we write out a global weston config?
# @param weston_ini_path
#   Where is the global weston.ini
# @param weston_ini_owner
#   Probably root
# @param weston_ini_group
#   Probably root
# @param weston_ini_mode
#   This should be world readable
# @param weston_ini_settings
#   A hash of the settings you want.
#   weston::weston_ini_settings:
#     shell:
#       'clock-format': 'seconds-24h'
#
# @example
#   include weston
class weston (
  Boolean $manage_packages = true,
  Array[String[1]] $package_names = ['weston'],
  Stdlib::Ensure::Package $packages_ensure = 'present',
  Boolean $manage_weston_ini = false,
  Boolean $manage_weston_ini_dir = false,
  Stdlib::Absolutepath $weston_ini_path = '/etc/xdg/weston/weston.ini',
  String $weston_ini_owner = 'root',
  String $weston_ini_group = 'root',
  String $weston_ini_mode = '0644',
  Hash $weston_ini_settings = {},
) {
  if $manage_packages {
    package { $package_names:
      ensure => $packages_ensure,
    }
  }

  if $manage_weston_ini_dir {
    file { dirname($weston_ini_path):
      ensure => 'directory',
      owner  => $weston_ini_owner,
      group  => $weston_ini_group,
      mode   => $weston_ini_mode,
    }
  }

  if $manage_weston_ini {
    file { $weston_ini_path:
      ensure  => 'file',
      owner   => $weston_ini_owner,
      group   => $weston_ini_group,
      mode    => $weston_ini_mode,
      content => epp('weston/etc/xdg/weston/weston.ini.epp', { 'stanzas' => $weston_ini_settings }),
    }
  }
}
