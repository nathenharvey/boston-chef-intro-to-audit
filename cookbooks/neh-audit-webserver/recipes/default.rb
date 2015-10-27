#
# Cookbook Name:: neh-audit-webserver
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
control_group 'neh - web server' do
  control 'home page is not owned by root user' do
    describe file('/var/www/html/index.html') do
      it { should_not be_owned_by 'root' }
    end
  end
end

