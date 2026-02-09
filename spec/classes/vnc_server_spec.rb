# frozen_string_literal: true

require 'spec_helper'

describe 'weston::vnc_server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'when using defaults' do
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to have_concat__fragment_resource_count(2)
        }
        it {
          is_expected.to contain_file('/usr/libexec/weston-vnc')
            .with_ensure('file')
            .with_owner('root')
            .with_group('root')
            .with_mode('0755')
        }

        it {
          is_expected.to contain_file('/etc/xdg/weston/vncserver.opts')
            .with_ensure('file')
            .with_owner('root')
            .with_group('root')
            .with_mode('0644')
            .with_content(%r{^OPTS=""$})
        }

        it {
          is_expected.to contain_concat('/etc/xdg/weston/vncserver.users')
            .with_owner('root')
            .with_group('root')
            .with_mode('0644')
        }
        it {
          is_expected.to contain_concat__fragment('vnc user file header')
        }
        it {
          is_expected.to contain_systemd__manage_unit('system weston vnc unit')
            .with_ensure('present')
            .with_name('weston-vncserver@.service')
            .with_unit_entry({
                               'Description' => 'Remote desktop service (VNC) with Weston',
                               'After' => ['syslog.target', 'network.target', 'systemd-user-sessions.service', 'remote-fs.target'],
                             })
            .with_service_entry({
                                  'Type' => 'notify',
                                  'User'           => '%I',
                                  'PAMName'        => 'login',
                                  'Environment'    => 'XDG_SESSION_TYPE=wayland',
                                  'ExecStart'      => '/usr/libexec/weston-vnc',
                                  'StandardOutput' => 'journal',
                                  'StandardError'  => 'journal',
                                })
            .with_install_entry({ 'WantedBy' => 'multi-user.target', })
        }
        it {
          is_expected.to contain_systemd__manage_unit('user weston vnc unit')
            .with_ensure('present')
            .with_name('weston-user-vncserver@.service')
            .with_path('/etc/systemd/user')
            .with_unit_entry({
                               'Description' => 'Remote desktop service (VNC) with Weston',
                             })
            .with_service_entry({
                                  'Type' => 'notify',
                                  'PAMName'        => 'login',
                                  'Environment'    => 'XDG_SESSION_TYPE=wayland',
                                  'ExecStart'      => '/usr/libexec/weston-vnc --port %I',
                                  'StandardOutput' => 'journal',
                                  'StandardError'  => 'journal',
                                })
            .with_install_entry({ 'WantedBy' => 'default.target', })
        }
        it {
          is_expected.to contain_concat('/etc/polkit-1/rules.d/25-puppet-weston-vnc_server.rules')
            .with_owner('root')
            .with_group('root')
            .with_mode('0644')
        }
        it {
          is_expected.to contain_concat__fragment('polkit_header')
        }
      end

      context 'when no manage' do
        let(:params) do
          {
            'manage_vnc_start_script' => false,
            'manage_vnc_options_file' => false,
            'manage_vnc_users_file' => false,
            'manage_systemd_unit_file' => false,
            'manage_systemd_user_unit_file' => false,
            'manage_vnc_services' => false,
            'manage_vnc_polkit_file' => false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to have_concat__fragment_resource_count(0) }
        it { is_expected.not_to contain_file('/usr/libexec/weston-vnc') }
        it { is_expected.not_to contain_file('/etc/xdg/weston/vncserver.opts') }
        it { is_expected.not_to contain_concat('/etc/xdg/weston/vncserver.users') }
        it { is_expected.not_to contain_systemd__manage_unit('system unit: weston-vncserver@.service') }
        it { is_expected.not_to contain_systemd__manage_unit('user unit: weston-vncserver@.service') }
        it { is_expected.not_to contain_concat('/etc/polkit-1/rules.d/25-puppet-weston-vnc_server.rules') }
      end

      context 'with complex params' do
        let(:params) do
          {
            'vnc_start_script' => '/vnc_start_script',
            'vnc_start_script_mode' => '0123',
            'vnc_options_file' => '/vnc_options_file',
            'vnc_options_file_mode' => '1234',
            'vnc_server_options' => ['--option-a', '--asdf'],
            'vnc_users_file' => '/vnc_users_file',
            'vnc_users_file_mode' => '2345',
            'systemd_template_startswith' => 'systemd_template_startswith',
            'systemd_template_endswith' => '.path',
            'systemd_user_template_startswith' => 'systemd_user_template_startswith',
            'systemd_user_template_endswith' => '.socket',
            'vnc_polkit_file' => '/vnc_polkit_file',
            'vnc_polkit_file_mode' => '3456',
            'default_user_can_control_service' => true,
            'default_extra_users_can_control_service' => ['userB', 'userA'],
            'vnc_sessions' => {
              'user' => {
                'comment' => 'comment text',
                'displaynumber' => 0,
                'ensure' => 'running',
                'enable' => true,
                'extra_users_can_control_service' => ['userC', 'userA']
              },
              'userA' => {
                'displaynumber' => 5902,
                'user_can_control_service' => false,
              },

            }
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to have_concat__fragment_resource_count(5)
        }
        it {
          is_expected.to contain_file('/vnc_start_script')
            .with_ensure('file')
            .with_owner('root')
            .with_group('root')
            .with_mode('0123')
        }

        it {
          is_expected.to contain_file('/vnc_options_file')
            .with_ensure('file')
            .with_owner('root')
            .with_group('root')
            .with_mode('1234')
            .with_content(%r{^OPTS="--asdf --option-a"$})
        }

        it {
          is_expected.to contain_concat('/vnc_users_file')
            .with_owner('root')
            .with_group('root')
            .with_mode('2345')
        }
        it {
          is_expected.to contain_concat__fragment('vnc user file header')
        }
        it {
          is_expected.to contain_concat__fragment('vnc user user')
            .with_content(%r{^# comment text$})
            .with_content(%r{^:5900=user$})
        }
        it {
          is_expected.to contain_concat__fragment('vnc user userA')
            .with_content(%r{^:5902=userA$})
        }
        it {
          is_expected.to contain_systemd__manage_unit('system weston vnc unit')
            .with_name('systemd_template_startswith@.path')
            .with_service_entry({
                                  'Type' => 'notify',
                                  'User'           => '%I',
                                  'PAMName'        => 'login',
                                  'Environment'    => 'XDG_SESSION_TYPE=wayland',
                                  'ExecStart'      => '/vnc_start_script',
                                  'StandardOutput' => 'journal',
                                  'StandardError'  => 'journal',
                                })
        }
        it {
          is_expected.to contain_systemd__manage_unit('user weston vnc unit')
            .with_name('systemd_user_template_startswith@.socket')
            .with_service_entry({
                                  'Type' => 'notify',
                                  'PAMName'        => 'login',
                                  'Environment'    => 'XDG_SESSION_TYPE=wayland',
                                  'ExecStart'      => '/vnc_start_script --port %I',
                                  'StandardOutput' => 'journal',
                                  'StandardError'  => 'journal',
                                })
        }
        it {
          is_expected.to contain_service('systemd_template_startswith@user.path')
            .with_ensure('running')
            .with_enable(true)
        }
        it {
          is_expected.to contain_service('systemd_template_startswith@userA.path')
            .with_ensure(nil)
            .with_enable(nil)
        }
        it {
          is_expected.to contain_concat('/vnc_polkit_file')
            .with_owner('root')
            .with_group('root')
            .with_mode('3456')
        }
        it {
          is_expected.to contain_concat__fragment('polkit_header')
        }
        it {
          is_expected.to contain_concat__fragment('polkit entry for user vnc service')
            .with_content(%r{subject.user == "user"})
            .with_content(%r{subject.user == "userA"})
            .with_content(%r{subject.user == "userB"})
            .with_content(%r{subject.user == "userC"})
        }
        it {
          is_expected.not_to contain_concat__fragment('polkit entry for userA vnc service')
        }
      end
      context 'with simple params' do
        let(:params) do
          {
            'default_vnc_service_ensure' => 'stopped',
            'default_vnc_service_enable' => false,
            'vnc_sessions' => {
              'user' => {
                'displaynumber' => 1,
                'ensure' => 'running',
                'enable' => true,
                'user_can_control_service' => true,
              },
              'userA' => {
                'displaynumber' => 5902,
              },

            }
          }
        end

        it {
          is_expected.to contain_service('weston-vncserver@user.service')
            .with_ensure('running')
            .with_enable(true)
        }
        it {
          is_expected.to contain_service('weston-vncserver@userA.service')
            .with_ensure('stopped')
            .with_enable(false)
        }
        it {
          is_expected.to contain_concat__fragment('polkit entry for user vnc service')
            .with_content(%r{subject.user == "user"})
        }
        it {
          is_expected.not_to contain_concat__fragment('polkit entry for userA vnc service')
        }
      end
    end
  end
end
