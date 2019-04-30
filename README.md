# Standalone MySQL via BOSH

## Goal: deploy and manage instances of Pivotal MySQL without needing a PCF/PAS installation

This approach uses BOSH Bootloader, aka _bbl_, to deploy/configure a BOSH Director in a cloud.  
Once that Director is deployed, the BOSH steps should run similarly, regardless of which cloud you've deployed to.

## Here's the procedure (assuming you're running a Mac / OSX)

1. [Install Dependencies](https://github.com/cloudfoundry/bosh-bootloader#prerequisites)
1. [Install bosh-bootloader](https://github.com/cloudfoundry/bosh-bootloader#install-bosh-bootloader-using-a-package-manager)
   The IaaS-specific guides aren't consistent about the state directory, so do this now:  
   ```
   $ mkdir some-state-dir
   $ cd some-state-dir
   ```
1. [Follow the appropriate IaaS-specific guide](https://github.com/cloudfoundry/bosh-bootloader#iaas-specific-getting-started-guides).
   **Caveat**: I was unsuccessful using GCP, but AWS EC2 worked just fine.
1. Once that part is finished,
   [target the BOSH Director](https://github.com/cloudfoundry/bosh-bootloader/blob/master/docs/howto-target-bosh-director.md),
   so that you can move on to deploying your BOSH release.  This entails the following, from within `some-state-dir`:  
   ```
   $ eval "$(bbl print-env)"
   ```
1. Go up one directory level: `$ cd ..`
1. Clone the pxc-release repo: `git clone https://github.com/cloudfoundry-incubator/pxc-release.git`
1. We'll follow the [instructions for deploying a standalone MySQL](https://github.com/cloudfoundry-incubator/pxc-release#deploying-pxc-release-standalone),
   with additional "aspects", such as creating a database, with a user and password.
1. There are a couple of prerequisites which aren't specifically called out in that procedure.  The first of which is to
   [upload the stemcell](https://bosh.io/docs/uploading-stemcells/) (takes about 5 minutes):  
   ```
   $ bosh upload-stemcell \
     https://s3.amazonaws.com/bosh-aws-light-stemcells/250.29/light-bosh-stemcell-250.29-aws-xen-hvm-ubuntu-xenial-go_agent.tgz \
     --sha1 3e1dd5c8580208cb07cec5df490fbed6145ad907
   ```
1. The second prerequisite is to [upload the BOSH release](https://bosh.io/docs/uploading-releases/) for `bpm`, a dependency:  
   ```
   $ bosh upload-release --sha1 41df19697d6a69d2552bc2c132928157fa91abe0 \
     https://bosh.io/d/github.com/cloudfoundry-incubator/bpm-release?v=1.0.4
   ```
1. Now, upload the BOSH release for pxc-release (the MySQL release):  
   ```
   $ bosh upload-release --sha1 eb53d366af2d6e49e8c2ac834191547b2ba44d30 \
     https://bosh.io/d/github.com/cloudfoundry-incubator/pxc-release?v=0.16.0
   ```
1. Create the `ops file` instructing BOSH to create a database and a user.  [Here's an example](./seeded-databases.yml):  
   ```
   $ cat  pxc-release/operations/seeded-databases.yml
   ---

   - type: replace
     path: /instance_groups/name=mysql/jobs/name=pxc-mysql/properties/seeded_databases?/name=demo_db?
     value:
       name: demo_db
       username: demo_user
       password: changeme
   ```
1. Deploy the MySQL release, which took 23 minutes in my case:  
   ```
   pxc="pxc-release"
   ops="$pxc/operations"

   bosh -d pxc deploy $pxc/pxc-deployment.yml -o $ops/seeded-databases.yml
   ```
 1. Run `bosh vms` to get the
