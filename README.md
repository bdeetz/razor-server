# Razor server
## FORK MAINTAINER NOTES
This is a fork of Puppet Labs' razor-server project. This fork adds the ability to create a fully bootstrapped version of Razor as a container. The motivation behind this repo and the container strategy is to avoid a situation where build artifacts and 3rd party libraries may become unavailable. This situation is already a reality due to what appears to be a lack of contributions to the upstream repo for over a year. To understand how to develop and deploy this tool within the context of SWCCDC see [CCDC_README.md](CCDC_README.md).

## What is Razor
Razor is an advanced provisioning application which can deploy both
bare-metal and virtual systems. It's aimed at solving the problem of how to
bring new metal into a state where your existing DevOps/configuration
management workflows can take it over.

Newly added machines in a Razor deployment will PXE-boot from a special Razor
Microkernel image, then check in, provide Razor with inventory information,
and wait for further instructions. Razor will consult user-created policy
rules to choose which tasks to apply to a new node, which will begin to
follow the task directions, giving feedback to Razor as it completes various
steps. Tasks can include steps for handoff to a DevOps system such as
[Puppet](https://github.com/puppetlabs/puppet) or to any other system capable
of controlling the node (such as a vCenter server taking possession of ESX
systems).

## Getting in touch

* bug/issue tracker: [RAZOR project in JIRA](https://tickets.puppetlabs.com/browse/RAZOR)
* on IRC: `#puppet-razor` on [freenode](http://freenode.net/)
* mailing list: [puppet-razor@googlegroups.com](http://groups.google.com/group/puppet-razor)

## Getting started

The [Wiki](https://github.com/puppetlabs/razor-server/wiki) has all the
details; in particular look at

* [Installation](https://github.com/puppetlabs/razor-server/wiki/Installation): how to get a Razor environment up and running
* [Getting started](https://github.com/puppetlabs/razor-server/wiki/Getting-started): using the CLI to do useful things
* [Developer setup](https://github.com/puppetlabs/razor-server/wiki/Developer-setup): for when you feel like hacking
* [Documentation](./doc/index.md): for when you want to learn how to use Razor

## What does Razor do anyway?

Razor is a power control, provisioning, and management application designed
to deploy both bare-metal and virtual computer resources. Razor provides
broker plugins for integration with third party configuration systems such
as Puppet.

Razor does this by discovering new nodes using
[facter](https://github.com/puppetlabs/facter), tagging nodes using facts
based on user-supplied rules and deciding what to install through matching
tags to user-supplied policies. Installation itself is handled flexibly
through ERB templating all installer files. Once installation completes,
the node can be handed off to a broker, typically a configuration
management system. Razor makes this handoff seamless and flexible.

## Razor MicroKernel

The [MicroKernel](https://github.com/puppetlabs/razor-el-mk) is a small OS
image that Razor boots on new nodes to do discovery. It periodically
submits [facts](https://github.com/puppetlabs/facter) about the node and
waits for instructions from the server about what to do next, if anything.

A [prebuilt archive](http://pup.pt/razor-microkernel-latest)
is available.

## Razor Client

The [Client](https://github.com/puppetlabs/razor-client) is a small Ruby
script that makes interacting with the server from the command line
easier. It lets you explore what the server knows about your
infrastructure, and modify how machines are provisioned, by interacting
with the
[Razor server API](https://github.com/puppetlabs/razor-server/blob/master/doc/api.md)

## Reference

* Original Razor Overview: [Nickapedia.com](http://nickapedia.com/2012/05/21/lex-parsimoniae-cloud-provisioning-with-a-razor)
* Razor Session from PuppetConf 2012: [Youtube](http://www.youtube.com/watch?v=cR1bOg0IU5U)


## License

Razor is distributed under the Apache 2.0 license.
See [the LICENSE file](LICENSE) for full details.
