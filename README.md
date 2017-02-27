# BOSH Lite for Windows
A lite development env for BOSH for Windows based on [bosh-lite](https://github.com/cloudfoundry/bosh-lite)

## BOSH Lite

* Slack: #bosh on <https://slack.cloudfoundry.org>
* Mailing lists:
  - [cf-bosh](https://lists.cloudfoundry.org/pipermail/cf-bosh) for asking BOSH usage and development questions
  - [cf-dev](https://lists.cloudfoundry.org/pipermail/cf-dev) for asking CloudFoundry questions
* CI: <https://bosh-lite.ci.cf-app.com/pipelines/bosh-lite>
* Roadmap: [Pivotal Tracker](https://www.pivotaltracker.com/n/projects/956238) (label:bosh-lite)

BOSH Lite is a pre-built [Vagrant](https://www.vagrantup.com/) box which includes [the Director](http://bosh.io/docs/terminology.html#director). It uses containers (via Warden/Garden CPI) to emulate VMs which makes it an excellent choice for:

- General BOSH exploration without investing time and resources to configure an IaaS
- Development of releases (including BOSH itself)
- Testing releases locally or in CI

This readme walks through deploying Cloud Foundry with BOSH Lite. BOSH and BOSH Lite can be used to deploy just about anything once you've got the hang of it.


## Install BOSH Lite

### Install and Boot a Virtual Machine

Installation instructions for different Vagrant providers:

* VirtualBox (below)

#### Using the VirtualBox Provider

1. Make sure your machine has at least 8GB RAM, and 100GB free disk space. Smaller configurations may work.

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

    Known working version:

    ```
    $ VBoxManage --version
    5.1...
    ```

    Note: If you encounter problems with VirtualBox networking try installing [Oracle VM VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads) as suggested by [Issue 202](https://github.com/cloudfoundry/bosh-lite/issues/202). Alternatively make sure you are on VirtualBox 5.1+ since previous versions had a [network connectivity bug](https://github.com/concourse/concourse-lite/issues/9).

1. Start Vagrant from the base directory of this repository, which contains the Vagrantfile. The most recent version of the BOSH Lite boxes will be downloaded by default from the Vagrant Cloud when you run `vagrant up`. If you have already downloaded an older version you will be warned that your version is out of date.

    ```
    $ vagrant up
    ```

1. When you are not using your VM we recommmend to *Pause* the VM from the VirtualBox UI (or use `vagrant suspend`), so that VM can be later simply resumed after your machine goes to sleep or gets rebooted. Otherwise, your VM will be halted by the OS and you will have to recreate previously deployed software.

1. Connect to BOSH Director VM

Tge BOSH CLI is not compatible with Windows. Therefore we need to connect to the director VM and work from there:

    ```
    $ vagrant ssh
    ```

1. Target the BOSH Director. When prompted to log in, use admin/admin.

    ```
    # if behind a proxy, exclude both the VM's private IP and xip.io by setting no_proxy (xip.io is introduced later)
    $ export no_proxy=xip.io,192.168.50.4

    $ bosh target 192.168.50.4 lite
    Target set to `Bosh Lite Director'
    Your username: admin
    Enter password: *****
    Logged in as `admin'
    ```
	
### Customizing the Local VM IP

The local VMs (virtualbox, vmware providers) will be accessible at `192.168.50.4`. You can optionally change this IP, uncomment the `private_network` line in the appropriate provider and change the IP address.

```
  config.vm.provider :virtualbox do |v, override|
    # To use a different IP address for the bosh-lite director, uncomment this line:
    # override.vm.network :private_network, ip: '192.168.59.4', id: :local
  end
```

### CA certificate

CA certificate that can be used with the BOSH CLI is saved in `ca/certs/ca.crt`. It's created for `192.168.50.4` and `*.sslip.io`.

## Deploy Cloud Foundry

See [deploying Cloud Foundry documentation](http://docs.cloudfoundry.org/deploying/boshlite/deploy_cf_boshlite.html) for detailed instructions.  
[CF Release](https://github.com/cloudfoundry/cf-release) is checked out  as `~/cf-release`.

Run follwing command to delpoy Cloud Foundry:

    ```
    $ ~/bosh-lite/bin/provision_cf
    ```

## Connect to Cloud Foundry
	
1. Add a route entry to your local routing table to enable access from your host to Cloud Foundry

Launch an evelated shell.

    ```
    $ route ADD 10.244.0.0 MASK 255.255.0.0 192.168.50.4
    ```

To make the route persistent across reboot add `-p`.

1. Install Cloud Foundry CLI on your host

[Latest Cloud Foundry CLI](https://github.com/cloudfoundry/cli/releases)

1. Connect to Cloud Foundry from your host

    ```
    $ cf login -a api.bosh-lite.com -u admin -p admin --skip-ssl-validation
    ```
	
## Troubleshooting

* [See troubleshooting doc](docs/troubleshooting.md) for solutions to common problems

## Miscellaneous

* [Warden CPI's cloud properties](http://bosh.io/docs/warden-cpi.html) for configuring deployment manifest
* [bosh cck documentation](docs/bosh-cck.md) for restoring deployments after VM reboot
* [bosh ssh documentation](docs/bosh-ssh.md) for SSH into deployment jobs
* [Offline documentation](docs/offline-dns.md) to configure BOSH lite firewall rules
* [xip.io](http://xip.io) to access local IPs via DNS
* [Dev documentation](docs/dev.md) to find out how to build custom bosh-lite boxes