# @summary Map defined VNC servers into NOVNC client
#
# @param vnc_server_hostname
#   Hostname to use as the default server target
# @param vnc_servers
#   Hash of vnc_servers to export.
#   You probably should just let inheritance do the work here
class weston::vnc_server::export_novnc (
  String $vnc_server_hostname = 'localhost',
  Hash $vnc_sessions = $weston::vnc_server::vnc_sessions,
) inherits weston::vnc_server {
  $connections = $vnc_sessions.reduce({}) |$memo, $user_info| {
    $displaynumber = $user_info[1]['displaynumber']
    if $displaynumber < 5900 {
      $real_displaynumber = $displaynumber + 5900
    } else {
      $real_displaynumber = $displaynumber
    }
    $memo + { $user_info[0] => "${vnc_server_hostname}:${real_displaynumber}" }
  }

  class { 'novnc':
    vnc_servers => $connections,
  }
}
