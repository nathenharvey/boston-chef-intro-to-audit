#
# Cookbook Name:: neh-webserver
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
package 'apache2'

service 'apache2' do
  action [:start, :enable]
end

file '/var/www/html/index.html' do
  content "<h1>Hello, world!</h1>"
  user 'root'
  group 'root'
end
