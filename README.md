[![Gem Version](https://badge.fury.io/rb/idb.svg)](http://badge.fury.io/rb/idb)
[![Dependency Status](https://gemnasium.com/dmayer/idb.png)](https://gemnasium.com/dmayer/idb)
[![Code Climate](https://codeclimate.com/github/dmayer/idb.png)](https://codeclimate.com/github/dmayer/idb)
<img src="https://stats.cysec.org/piwik.php?idsite=2&rec=1" style="border:0" alt="" />

# Idb

idb is a tool to simplify some common tasks for iOS pentesting and research. Originally there was a command line version of the tool, but it is no longer under development so you should get the GUI version.

idb was released as part of a talk at [ShmooCon](http://shmoocon.org) 2014. The [slides of the talk](https://speakerdeck.com/dmayer/introducing-idb-simplified-blackbox-ios-app-pentesting) are up on [Speakerdeck](https://speakerdeck.com/dmayer/introducing-idb-simplified-blackbox-ios-app-pentesting). [Video](https://archive.org/details/ShmooCon2014_Introducing_idb_Simplified_Blackbox_iOS_App_Pentesting) is available on [archive.org](http://www.archive.org) There is also a [blog post](http://cysec.org/blog/2014/01/23/idb-ios-research-slash-pentesting-tool/) on my [personal website](http://cysec.org).

## Installation

idb has some prerequisites. As it turns out, things like ruby and Qt are difficult to bundle into a stand-alone installer. While idb itself can easily be installed via Ruby Gems, you need to have some additional software first:

### 1. Prerequisites 
####  1.1 Ruby Environment
idb requires a valid ruby 1.9.3 or 2.1 installation and it is recommended to install the used ruby using [RVM](https://rvm.io/). **Ruby 2.0 does not work properly** due to issues with qtbindings.

**Important Note:** Shared library support is required! This is the default for many system rubies, but if you install a ruby via `rvm` or similar, you need to do one of the following:
* **Under `rvm` use `rvm install 2.1 --enable-shared` when installing ruby.**
* Under `ruby-install`/`chruby` use `-- --enable-shared` when installing ruby.
* Under `ruby-build`/`rbenv` with `ruby-build` use `CONFIGURE_OPTS=--enable-shared [command]` when installing Ruby.

#### 1.2 Install Other Prerequisites:
*  OS X: `brew install qt cmake usbmuxd libimobiledevice`
*  Ubuntu: `apt-get install cmake libqt4-dev git-core libimobiledevice-utils libplist-utils usbmuxd -y`

### 2. Installing idb
#### 2.1 Production Use
*  Install idb: `gem install idb`
  *  On Linux install prerequisites first: `apt-get install libxml2-dev libsqlite3-dev`
*  Run idb: `idb`
*  Hooray!

#### 2.2 Development
* Clone the repository `git clone https://github.com/dmayer/idb`
* `cd idb`
* `bundle install` (using the right ruby version)
* As for every ruby gem, the application code lives in the `lib` folder 
* Run idb by calling `bundle exec rake run`
  * Note: Running `bin/idb` directly won't work since it will not find the idb gem (or use the installed gem and not the checked out source code).  Instead, the `rake` task runs idb in the current bundler environment where bundler supplies the gem from source. 


## Usage

See the basic [manual and walk-through](//github.com/dmayer/idb/wiki/Manual-and--Walk-Through) to get started.

**New as of October 2014:** Idb now stores its configuration and temporary files in `~/.idb/`

## FAQ

### Q: After starting idb, the menu bar does not appear
A: This seems to be a bug when using ruby 2.1 on OS X. I have no idea why this is happening, but switching to a different application and the back to idb fixes it. Any pointers on how to fix this are greatly appreciated!


## Contributing

1. Fork it ( https://github.com/[my-github-username]/idb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
