#
# Cookbook Name:: deploy_s3
#
# Copyright 2012, HipSnip Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'fileutils'

action :create do
  log %Q(Deploying build "#{new_resource.build}" for application "#{new_resource.application}")

  deploy_root = new_resource.deploy_root ? new_resource.deploy_root : node['deploy_s3']['deploy_root']
  builds_bucket = new_resource.bucket ? new_resource.bucket : node['deploy_s3']['bucket']
  app_root = ::File.join(deploy_root, new_resource.application)
  release_root = ::File.join(app_root, 'releases')

  directory release_root do
    mode new_resource.mode
    recursive true
    user new_resource.user if new_resource.user
    group new_resource.group if new_resource.group
    action :create
  end


  raise "You need to set at least the [:deploy_s3][:bucket] attribute if the bucket attribute of the lwrp is empty" if builds_bucket.empty?

  build_source = "s3://#{builds_bucket}/#{new_resource.application}/#{new_resource.build}.tar.gz"
  release_path = ::File.join(release_root, new_resource.build)
  destination_path = "#{release_path}.tar.gz"
  symlink = ::File.join(app_root, 'latest')

  if ! ::File.exists?(symlink) or ! ::File.exists?(release_path) or ::File.readlink(symlink) != release_path

    ruby_block "build_install" do
      block do

        if ::File.size?(destination_path)
          Chef::Log.info %Q("#{destination_path}" is already downloaded)
        else
          Chef::Log.info %Q(Downloading build "#{build_source}" from S3 to "#{destination_path}")
          `s3cmd get #{build_source} #{destination_path} --skip-existing`
          raise "Failed to download build '#{build_source}' from S3 - either the path or permissions are wrong" unless ::File.size?(destination_path)
        end


        Chef::Log.info %Q(Extracting build "#{destination_path}")
        `tar -xzf #{destination_path} -C #{release_root}`
        raise "Failed to extract '#{destination_path}'" unless ::File.exists? release_path


        if ::File.exists? destination_path
          Chef::Log.info "Removing build archive"
          begin
            ::File.delete destination_path
          rescue
            Chef::Log.warn %Q(Failed to remove "#{destination_path}")
          end
        end


        if new_resource.user && new_resource.group
          Chef::Log.info %Q(Changing owner of "#{release_path}" to #{new_resource.user}:#{new_resource.group})
          `chown #{new_resource.user}:#{new_resource.group} -R #{release_path}`
        elsif new_resource.user
          Chef::Log.info %Q(Changing owner of "#{release_path}" to #{new_resource.user})
          `chown #{new_resource.user} -R #{release_path}`
        elsif new_resource.group
          Chef::Log.info %Q(Changing group of "#{release_path}" to #{new_resource.group})
          `chgrp #{new_resource.group} -R #{release_path}`
        end

        Chef::Log.info %Q(Changing permissions on "#{release_path}" to #{new_resource.mode})
        `chmod -R #{new_resource.mode} #{release_path}`


        Chef::Log.info %Q(Updating Symlink "#{symlink}")
        # Symlink overwriting seems to do some weird stuff, so remove it first...
        FileUtils::rm symlink, :force => true
        FileUtils::ln_s release_path, symlink

      end

      action :create
    end

    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Package #{new_resource.build} already installed"
  end
end