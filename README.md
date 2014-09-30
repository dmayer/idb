# Idb

idb is a tool to simplify some common tasks for iOS pentesting and research. Originally there was a command line version of the tool, but it is no longer under development so you should get the GUI version.

idb was released as part of a talk at [ShmooCon](http://shmoocon.org) 2014. The [slides of the talk](https://speakerdeck.com/dmayer/introducing-idb-simplified-blackbox-ios-app-pentesting) are up on [Speakerdeck](https://speakerdeck.com/dmayer/introducing-idb-simplified-blackbox-ios-app-pentesting). [Video](https://archive.org/details/ShmooCon2014_Introducing_idb_Simplified_Blackbox_iOS_App_Pentesting) is available on [archive.org](http://www.archive.org) There is also a [blog post](http://cysec.org/blog/2014/01/23/idb-ios-research-slash-pentesting-tool/) on my [personal website](http://cysec.org).

## Installation

I am currently working on making the installation proces much more pleasant. It is not fully auomated yet, but the dependencies and number steps are much simpler since I bundled idb into a gem. Basic instructions:

* Install ruby (1.9.3 and 2.1 are known to work. **Don't use 2.0**)
  * **Shared library support is required!** 
    * Under `rvm` use `--enable-shared` when installing ruby.
    * Under `ruby-install`/`chruby` use `-- --enable-shared` when installing ruby.
    * Under `ruby-build`/`rbenv` with `ruby-build` use `CONFIGURE_OPTS=--enable-shared [command]` when installing Ruby.
* Install prerequisites:
    *  OS X: `brew install qt cmake usbmuxd libimobiledevice`
    *  Ubuntu: `apt-get install cmake libqt4-dev git-core libimobiledevice-utils libplist-utils usbmuxd -y`
*  Install idb: `gem install idb`
*  Run idb: `idb`
*  Hooray!

Expect a fully bundled version which includes ruby and qt soon!

## Usage

See the basic [manual and walk-through](//github.com/dmayer/idb/wiki/Manual-and--Walk-Through) to get started.

## FAQ

### Q: After staring idb, the menu bar does not appear
A: This seems to be a bug when using ruby 2.1 on OS X. I have no idea why this is happening, but switching to a different application and the back to idb fixes it. Any pointers on how to fix this are greatly appreciated!


## Contributing

1. Fork it ( https://github.com/[my-github-username]/idb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
