name             "deploy_s3"
maintainer       "HipSnip Ltd."
maintainer_email "adam@hipsnip.com"
license          "Apache 2.0"
description      "Provides a resource for downloading build packages and deploying them onto a server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.5.0"

depends "hipsnip-s3cmd"

attribute "deploy_s3/bucket",
  :display_name => "S3 bucket",
  :description => "The Amazon S3 bucket that contains all the builds",
  :type => "string",
  :required => "required",
  :default => ""


attribute "deploy_s3/deploy_root",
  :display_name => "Deployment Root",
  :description => "The folder in which you'll be creating this deployment",
  :type => "string",
  :required => "required",
  :default => "/home/web"