# gidb

gidb is a tool to simplify some common tasks for iOS pentesting and research. It is still a work in progress but already provides a bunch of (hopefully) useful commands. The goal was to provide all (or most) functionality for both, iDevices and the iOS simulator.  For this, a lot is abstracted internally to make it work transparently for both environments. Although recently the focus has been more on supporting devices.

idb was released as part of a talk at [ShmooCon](http://shmoocon.org) 2014. The [slides of the talk](https://speakerdeck.com/dmayer/introducing-idb-simplified-blackbox-ios-app-pentesting) are up on [Speakerdeck](https://speakerdeck.com/dmayer/introducing-idb-simplified-blackbox-ios-app-pentesting). [Video](https://archive.org/details/ShmooCon2014_Introducing_idb_Simplified_Blackbox_iOS_App_Pentesting) is available on [archive.org](http://www.archive.org) There is also a [blog post](http://cysec.org/blog/2014/01/23/idb-ios-research-slash-pentesting-tool/) on my [personal website](http://cysec.org).

## Getting Started 
Visit the [getting started guide](//github.com/dmayer/idb/wiki/Getting-started) on the wiki to get installation instructions. Next, there is a basic [manual and walk-through](//github.com/dmayer/idb/wiki/Manual-and--Walk-Through) available as well.

Bug reports, feature requests, and contributions are more than welcome!

## Command-Line Version
idb started out as a command line tool which is still accessible through the `cli` branch. Find the [getting started](//github.com/dmayer/idb/wiki/CLI-Version:-Getting-Started) guide and some more documentation in the wiki.

## gidb Features

* Simplified pentesting setup
    * Setup port forwarding 
    * Certificate management
* iOS log viewer
* Screen shot utility
    * Simplifies testing for the creation of backgrounding screenshots
* App-related functions
     * App binary
        * Download
        * List imported libraries
        * Check for encryption, ASLR, stack canaries
        * Decrypt and download an app binary (requires [dumpdecrypted](//github.com/stefanesser/dumpdecrypted))
     * Launch an app
     * View app details such as name, bundleid, and `Info.plist` file.
* Inter-Process Communication
     * URL Handlers
        * List URL handlers
        * Invoke and fuzz URL handlers
     * Pasteboard monitor
* Analyze local file storage
    * Search for, download, and view plist files
    * Search for, download, and view sqlite databases
    * Search for, download, and view local caches  (`Cache.db`)
    * File system browser
* Install utilities on iDevices 
    * Ii   
    * Install [iOS SSL killswitch](//github.com/iSECPartners/ios-ssl-kill-switch)
    * alpha: Compile and install [dumpdecrypted](//github.com/stefanesser/dumpdecrypted)
* Alpha:
  * Cycript console
  * Snoop-It integration

## Documentation
Some documentation can be found on the [wiki](//github.com/dmayer/idb/wiki).

## FAQ

### Q: After staring idb, the menu bar does not appear
A: This seems to be a bug when using ruby 2.1 on OS X. I have no idea why this is happening, but switching to a different application and the back to idb fixes it. Any pointers on how to fix this are greatly appreciated!
