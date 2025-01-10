# frozen_string_literal: true

require 'spec_helper'

describe 'weston' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'when using defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to have_package_resource_count(1) }
        it { is_expected.to have_file_resource_count(0) }
        it { is_expected.to contain_package('weston').with_ensure('present') }
      end
    end

    context 'with simple parameters' do
      let(:params) do
        {
          'package_names' => ['asdf', 'jkl'],
          'packages_ensure' => 'latest',
          'manage_weston_ini' => true,
          'weston_ini_settings' => { 'a' => { 'b' => 'c' } }
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to have_package_resource_count(2) }
      it { is_expected.to contain_package('asdf').with_ensure('latest') }
      it { is_expected.to contain_package('jkl').with_ensure('latest') }

      it { is_expected.to have_file_resource_count(1) }
      it {
        is_expected.to contain_file('/etc/xdg/weston/weston.ini')
          .with_ensure('file')
          .with_owner('root')
          .with_group('root')
          .with_mode('0644')
          .with_content(%r{^\[a\]$})
          .with_content(%r{^b=c$})
      }
    end

    context 'with parameters, but no manage' do
      let(:params) do
        {
          'manage_packages' => false,
          'package_names' => ['asdf', 'jkl'],
          'packages_ensure' => 'latest',
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to have_package_resource_count(0) }
    end

    context 'with parameters, and config' do
      let(:params) do
        {
          'manage_packages' => false,
          'package_names' => ['asdf', 'jkl'],
          'packages_ensure' => 'latest',
          'manage_weston_ini' => true,
          'weston_ini_path' => '/tmp/foo.ini',
          'weston_ini_settings' => { 'a' => { 'b' => 'c' } }
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to have_package_resource_count(0) }
      it { is_expected.to have_file_resource_count(1) }
      it {
        is_expected.to contain_file('/tmp/foo.ini')
          .with_ensure('file')
          .with_owner('root')
          .with_group('root')
          .with_mode('0644')
          .with_content(%r{^\[a\]$})
          .with_content(%r{^b=c$})
      }
    end
  end
end
