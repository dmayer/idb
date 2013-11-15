# idb

idb is a tool to simplify some common tasks for iOS pentesting and research. It is still a work in progress but already provides a bunch of (hopefully) useful commands. The goal was to provide all (or most) functionality for both, iDevices and the iOS simulator. For this, a lot is abstracted internally to make it work transparently for both environments. Below is a a link to the [getting started guide](//github.com/dmayer/idb/wiki/Getting-started) and also a [full command reference](//github.com/dmayer/idb/wiki/Idb-command-reference). Bug reports, feature requests, and contributions are more than welcome!

## Features

* Screen shot utility
    * Simplifies testing for the creation of backgrounding screenshots
* App-related functions
    * List registered URL handlers
    * Download an app binary
    * Decrypt and download an app binary (requires [dumpdecrypted](//github.com/iSECPartners/ios-ssl-kill-switch))
    * Launch an app
    * View app details such as name, bundleid, and `Info.plist` file.
* Analyze local file storage
    * Search for, download, and view plist files
    * Search for, download, and view sqlite databases
    * Search for, download, and view local caches  (`Cache.db`)
    * Create and download archive of entire app folder
* Install utilities on iDevices
    * Install [iOS SSL killswitch](//github.com/iSECPartners/ios-ssl-kill-switch)
    * Compile and install [dumpdecrypted](//github.com/stefanesser/dumpdecrypted)
* Manage certificates in the iOS Simulator trust store
    * Install (and delete) SSL certificates in the trust store in order to intercept TLS/HTTPS protected traffic

## Documentation
Comprehensive documentation can be found on the [wiki](//github.com/dmayer/idb/wiki).
