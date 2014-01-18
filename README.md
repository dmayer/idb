# gidb

gidb is a tool to simplify some common tasks for iOS pentesting and research. It is still a work in progress but already provides a bunch of (hopefully) useful commands. The goal was to provide all (or most) functionality for both, iDevices and the iOS simulator.  For this, a lot is abstracted internally to make it work transparently for both environments. Although recently the focus has been more on suporting devices.

## Getting Started 
Visit the [getting started guide](//github.com/dmayer/idb/wiki/Getting-started) on the wiki. Bug reports, feature requests, and contributions are more than welcome!

## Features

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
        * Check for encrypttion, ASLR, stack canaries
        * Decrypt and download an app binary (requires [dumpdecrypted](//github.com/iSECPartners/ios-ssl-kill-switch))
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


