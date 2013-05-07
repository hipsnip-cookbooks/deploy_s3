Description [![Build Status](https://travis-ci.org/hipsnip-cookbooks/deploy_s3.png)](https://travis-ci.org/hipsnip-cookbooks/deploy_s3)
===========
Somewhat similar to the Opscode deploy resource, but rather than hooking up to a source code repository, it downloads complete build packages from a specific Amazon S3 bucket.
The cookbook itself doesn't do much, besides providing an "s3_deploy" resource that takes care of the above.


Requirements
============
Needs the "s3cmd" cookbook to work. Tested on Ubuntu 11.10 and 12.04, but it should work on any platform that supports symlinks.


Attributes
==========

    ['deploy_s3']['bucket'] = The name of the bucket containing the releases
    ['deploy_s3']['deploy_root'] = The location where the app will be deployed on disk - defaults to "/home/web"


Usage
=====

Best to explain by example:

Let's assume we have an application called "myapp", and we want to deploy the build "v1.2" on our server.
We set the "bucket" attribute to "app-releases", and leave "deploy_root" as the default.

First, we need to store the build in the "app-releases" S3 bucket. The build should be a single folder named after the release name ("v1.2" in our case), which is then compressed with Tar/Gz. So for our example, the package would be "v1.2.tar.gz" which contains the folder "v1.2".

This folder is then uploaded into S3, inside a folder named after the app: "myapp/v1.2.tar.gz"

Then we'd put the following in our recipe

	deploy_s3 "myapp" do
		build "v1.2"
		bucket "mybucket"
		action :create
	end

and the resource will do the following:

1. Create the folder "/home/web/myapp" if it's not already there
2. Create the folder "/home/web/myapp/releases" if it's not already there
3. Attempt to download the object "mybucket/myapp/v1.2.tar.gz" from the "app-releases" bucket, into "/home/web/myapp/releases"
4. Unzip the package
5. Symlink the package to "/home/web/latest"


Development
===========
Please refer to the Readme [here](https://github.com/hipsnip-cookbooks/cookbook-development/blob/master/README.md)


License and Author
==================

Author:: Adam Borocz ([on GitHub](https://github.com/motns))

Copyright:: 2013, HipSnip Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
