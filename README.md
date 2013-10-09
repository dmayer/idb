# idb  ;-)

idb is a tool to simplify some common tasks for iOS pentesting and research.
It is still a work in prorgress but already provides a bunch of (hopefully) useful commands. The goal was to provide all
 (or most)  functionality for both, iDevices and the iOS simulator. For this, a lot is abstracted internally
   to make it work transparantly for both environments. Below is a getting started guide and also a full command
   reference. Bug reports and feature requests are more than welcome!


## Getting Started

**idb Host**

* Ruby 1.9
* `brew install sqlite`
* Run `bundle install`
* plistutil (stock on OS X, available via `apt-get install plistutil` on Debian-based Linux)

**iDevice**

* Jailbroken iOS 6.x (once iOS 7 gets a jailbreak I'll see how things change..)
* SSH access

# Documentation
 * [doc/usb_ssh.md](How-To: SSHing via USB)
 * [doc/idb_usage.md](idb Usage)
 * [doc/idb_command_reference.md](idb Command Reference)

