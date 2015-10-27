#
# Cookbook Name:: neh-audit-ntp
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
control_group 'neh - ntp' do
  control 'ntp is running and enabled' do
    describe service('ntp') do
      it { should be_running }
      it { should be_enabled }
    end
  end
end

