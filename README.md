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

### How-To: SSHing via USB

#### SSH config
In your `~/.ssh/config` add something like this:

    Host usb
    HostName 127.0.0.1
    Port 2222
    User root
    RemoteForward 8080 127.0.0.1:8080

This will map the hostname "usb" to an SSH connection to localhost on
port 2222 as root. You may wonder "But there is nothing listening on
2222!" Enter `usbmuxd`.


####Install usbmuxd
On OS X as easy as `brew install usbmuxd`
Then you can run `iproxy 2222 22` which will listen on port 2222 (aha!)
and forward all incoming connections via USB to port 22 of the iDevice.


#### Using SSH
A simple `ssh usb` will drop you right into an SSH shell (assuming you
have public key auth setup to the iDevice).


#### Burping
The SSH config also sets up port forwarding such that any connections to
port 8080 on the iDevice are forwarded to port 8080 locally (on the
laptop). So if you configure the proxy on the iDevice as
"localhost:8080" it will end up in burp (assuming it listens on 8080 on
your laptop).



## idb Usage

idb can be used in two ways as an interactive shell or as a command line utility which executes a single command.

    $ ruby idb.rb --help
    Command line utility to perform common tasks on iDevices and the iOS simulator.

    Usage:
           ruby irb.rb [options] [optional command]
    if [optional command] is specified, it is executed and idb exits. If it is omitted,
     an intractive idb prompt is displayed

    Valid [options] are:
         --simulator, -s:   Use simulator
            --device, -d:   Use iOS device via SSH
      --username, -u <s>:   SSH username (default: root)
      --password, -p <s>:   SSH password
      --hostname, -h <s>:   SSH hostname
          --port, -o <i>:   SSH port (default: 22)
           --version, -v:   Print version and exit
          --help, -e:   Show this message

### Usage with iDevice

To use idb with an iDevice run it, e.g.,  with the following command:

    ruby idb.rb --device --hostname localhost --port 2222 --username root --password alpine


### Usage with Simulator

To use idb with a simulator run it with the following command:

    ruby idb.rb --simulator

All available simulator versions are automatically detected and listed. After selecting a simulator one is
dropped into the interactive shell.

    $ ruby idb.rb --simulator
    Multiple simulators found::
    1. /Users/daniel/Library/Application Support/iPhone Simulator/6.0
    2. /Users/daniel/Library/Application Support/iPhone Simulator/6.1
    Choice
    1
    [*] Using simulator in /Users/daniel/Library/Application Support/iPhone Simulator/6.0.
    idb >

### Specifying the Command on the Command Line

For either mode, an optional command can be specified directly on the command line. If such a command
is present, it is executed and `idb` exits.

**Example:**

    ruby idb.rb --simulator cert reinstall ~/test.cert
    Multiple simulators found::
    1. /Users/daniel/Library/Application Support/iPhone Simulator/6.0
    2. /Users/daniel/Library/Application Support/iPhone Simulator/6.1
    Choice:
    1
    [*] Using simulator in /Users/daniel/Library/Application Support/iPhone Simulator/6.0.
    [*] Reading and converting certificate...
    [*] Removing exising entry from trust store...
    [*] Operation complete
    [*] Reading and converting certificate...
    [*] Inserting certificate into trust store...
    [*] Operation complete



## idb Commands

The available commands are grouped by main commands some of which support specific sub-commands.
The interactive readline interface supports tab completion.

Main Commands:

      app         - app related tools.
      install     - Installs various utilities on iDevices.
      cert        - Installs certificates into simulator key store.
      screenshot  - Util to detect if an app stores screenshots upon backgrounding.

The individual commands are described below.


### Application-related Functions



The `app` command provides various functions related to installed apps.

#### Overview

    idb > app
    app <option> where <option> is one of:

    Non App Specific
    ----------------
    list         - Lists all installed apps.
    select       - Selects an app for other operations.

    App Specific
    ------------
    archive      - Download application bundle as .tar.gz.
    bundleid     - Print bundle id.
    decrypt      - Decrypts and downloads application binary.
    download     - Downloads application binary.
    get_plists   - List, view, and download any .plist files.
    get_sqlite   - List, view, and download any .sqlite files.
    get_cachedb  - List and download any Cache.db files.
    launch       - Start the application.
    info_plist   - View or download Info.plist.
    name         - Print app name
    url_handlers - Lists URL handleres registered by app.


#### app list

Lists all installed apps including identifiers and binary names.

**Example:**

    idb > app list
    [*] Retrieving list of applications...
    E3AD855E-90C9-428C-AC31-9FC521165B2F (TV Guide.app)
    FCD785FC-B7F0-49D8-8A62-6A24EAF19B6C (Weather.app)

#### app select

Selects an app to be used with the remaining app commands. This is also automatically triggered when a
command requires an app to be selected. Once an app is selected, its id is displayed as part of the
idb prompt. The selected app can be changed by running `app select` again.

**Example:**

    idb > app select
    [*] Retrieving list of applications...
    Select which application to use:
    1. E3AD855E-90C9-428C-AC31-9FC521165B2F (TV Guide.app)
    2. FCD785FC-B7F0-49D8-8A62-6A24EAF19B6C (Weather.app)
    Choice:
    1
    [*] Using application E3AD855E-90C9-428C-AC31-9FC521165B2F.
    [*] Info.plist found at /private/var/mobile/Applications/E3AD855E-90C9-428C-AC31-9FC521165B2F//TV Guide.app/Info.plist
    [*] Parsing plist file..
    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app select

#### app download

Download the application binary to a `tmp` folder.

**Example:**

This example assumes that an app has been selected already. If not, it will prompt the user to select an app.

    db [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app download
    [*] Locating application binary...
    [*] Downloading binary /private/var/mobile/Applications/E3AD855E-90C9-428C-AC31-9FC521165B2F//TV Guide.app/TV Guide
    [*] Binary downloaded to tmp/E3AD855E-90C9-428C-AC31-9FC521165B2F/TV Guide.app

#### app decrypt (iDevice only)

Attempt to decrypt and then download an application binary.

**Example #1 (App is Encrypted):**

    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app decrypt
    [*] Checking if dumpdecrypted is installed...
    [*] dumpdecrypted found.
    [*] Locating application binary...
    [*] Running '/private/var/mobile/Applications/E3AD855E-90C9-428C-AC31-9FC521165B2F//TV Guide.app/TV Guide'
    [*] Checking if decrypted file /var/root/TV Guide.decrypted was created...
    [*] Decrypted file found. Downloading...
    [*] Decrypted binary downloaded to tmp/E3AD855E-90C9-428C-AC31-9FC521165B2F/TV Guide.app.decrypted

**Example #2 (App is not Encrypted):**

    idb [8357A903-B960-44DD-8FBF-CCE26F1E19D1] > app decrypt
    [*] Checking if dumpdecrypted is installed...
    [*] dumpdecrypted found.
    [*] Locating application binary...
    [*] Running /private/var/mobile/Applications/8357A903-B960-44DD-8FBF-CCE26F1E19D1//FakeApp.app/FakeApp
    [*] Checking if decrypted file /var/root/FakeApp was created...
    [*] Decryption failed. File may not be encrypted. Try 'app download' instead.


#### app get_plists

Finds all `.plist` files in the app directory and lists them. The user can then choose to either view it on screen
or open it in an external editor associated with `.plist`. This is helpful to check for insecure storage
mechanism via `NSUserDefaults`.


**Example:**

    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app get_plists
    [*] Looking for plist files...
    Select plist file to view::
    1. /iTunesMetadata.plist
    2. /TV Guide.app/Info.plist
    3. /TV Guide.app/ResourceRules.plist
    4. /Library/Preferences/com.apple.PeoplePicker.plist
    5. /Library/Preferences/com.roundbox.TVGuide.plist
    6. /TV Guide.app/TVGListings.momd/VersionInfo.plist
    7. /TV Guide.app/TVGNonPersistent.momd/VersionInfo.plist
    8. /TV Guide.app/TVGPurgeable.momd/VersionInfo.plist
    9. /TV Guide.app/channelicons/list.plist
    10. /Library/Caches/com.crashlytics.data/com.roundbox.TVGuide/f3c5a32a4bc4425ad174a142d4ee7ffee401f54f/settings.plist
    11. Quit
    Choice:
    3
    1. Display
    2. Open in external editor
    ?  1
    [*] Listing  /TV Guide.app/ResourceRules.plist.
    [*] Parsing plist file..
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>rules</key>
        <dict>
          <key>.*</key>
          <true/>
          <key>Info.plist</key>
          <dict>
            <key>omit</key>
            <true/>
            <key>weight</key>
            <real>10</real>
          </dict>
          <key>ResourceRules.plist</key>
          <dict>
            <key>omit</key>
            <true/>
            <key>weight</key>
            <real>100</real>
          </dict>
        </dict>
      </dict>
    </plist>
    Select plist file to view::



#### app get_sqlite


Finds all `.sqlite` files in the app directory and lists them. The user can then choose to either download the file,
 open it in the sqlite command line tool, or open it in an external editor  associated with `.sqlite`.
 This is helpful to check for insecure storage.


    db [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app get_sqlite
    [*] Looking for sqlite files...
    Select sqlite file::
    1. /Library/Caches/com.roundbox.TVGuide/TVGNonPersistent.sqlite
    2. /Library/Caches/com.roundbox.TVGuide/TVGPurgeable.sqlite
    3. Quit
    Choice:
    2
    What would you like to do?:
    1. Download
    2. Open in sqlite command line tool
    3. Open in external editor
    ?:



#### app get_cachedb


Finds all `Cache.db` files in the app directory and lists them. The user can then choose to either download the file or
 open it in the sqlite command line tool.
 This is helpful to check whether caching for `NSURLCache` issues which store requests and server responses.
  The `Cache.db` is a sqlite file and can be opened using any sqlite editor.


**Example:**

    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app get_cachedb
    [*] Looking for Cache.db files...
    Select Cache.db file::
    1. /Library/Caches/com.roundbox.TVGuide/Cache.db
    2. Quit
    Choice:
    1
    What would you like to do?:
    1. Download
    2. Open in sqlite command line tool
    ?  1


#### app launch

Launches the application. For running this on the iDevice the `open` command (`com.conradkramer.open`) needs to be installed. When `apt-get` is available on te device,
idb will do that automatically.

***Example:***

    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app launch
    [*] Launching app...


#### app url_handlers

Parses the `Info.plist` file and lists all the registered URL handlers / schemes.

**Example:**

    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app url_handlers
    [*] Registered URL schemas based on Info.plist:
    fb63084645929
    tvguide


#### app archive

Creates a `.tar.gz` of the entire application folder and downloads it.

**Example:**

    idb [E3AD855E-90C9-428C-AC31-9FC521165B2F] > app archive
    [*] Creating tar.gz of /private/var/mobile/Applications/E3AD855E-90C9-428C-AC31-9FC521165B2F. This may take a while...
    [*] Downloading app archive...
    [*] App archive downloaded to tmp/E3AD855E-90C9-428C-AC31-9FC521165B2F/app_archive.tar.gz.


#### app bundleid

Prints the bundle identifier of the currently selected app.

**Example:**

    idb [973B4F94-80BD-40CE-90F5-A2864C023D5E] > app bundleid
    Bundle identifier for 973B4F94-80BD-40CE-90F5-A2864C023D5E:
    com.krvw.iGoat

#### app name

Prints the name of the currently selected app.


**Example:**

    idb [973B4F94-80BD-40CE-90F5-A2864C023D5E] > app name
    Bianry name for 973B4F94-80BD-40CE-90F5-A2864C023D5E:
    iGoat



#### app info_plist

Downloads, outputs, or opens the `Info.plist` file of the current app.

    idb [631B463A-526C-442E-A639-C6095906DFB0] > app info_plist
    [*] Info.plist found at /Users/daniel/Library/Application Support/iPhone Simulator/6.0/Applications/631B463A-526C-442E-A639-C6095906DFB0//InvestMeIPad.app/Info.plist
    What would you like to do?:
    1. Download Info.plist
    2. Display Info.plist
    3. Open Info.plist in external editor (if associated)
    ?

**Example:**

    idb [973B4F94-80BD-40CE-90F5-A2864C023D5E] > app name
    Bianry name for 973B4F94-80BD-40CE-90F5-A2864C023D5E:
    iGoat

### Screenshot Utility

The `screenshot` utility simplifies the testing of the iOS screenshot vulnerability (the fact that iOS takes
 a screenshot of the current screen content whenever an app is backgrounded). Simply run `screenshot`, select the
  app under investigation and follow the instructions.


**Example:**

    idb > screenshot
    [*] Retrieving list of applications...
    Select which application to use:
    1. E3AD855E-90C9-428C-AC31-9FC521165B2F (TV Guide.app)
    Choice:
    1
    [*] Using application E3AD855E-90C9-428C-AC31-9FC521165B2F.
    [*] Info.plist found at /private/var/mobile/Applications/E3AD855E-90C9-428C-AC31-9FC521165B2F//TV Guide.app/Info.plist
    [*] Parsing plist file..
    Launch the app on the device. [press enter to continue]

    Now place the app into the background. [press enter to continue]

    New screen shot found:
    /private/var/mobile/Applications/E3AD855E-90C9-428C-AC31-9FC521165B2F/Library/Caches/Snapshots/com.roundbox.TVGuide/UIApplicationAutomaticSnapshotDefault-Portrait@2x.png
    Do you want to download and view it? (y/n)
    y



### Install Certificate Into Simulator Trust Store

*Disclaimer: This is inspired by Mike Tracy's `ios_sim_ts_insert.rb`*

These functions are useful to install SSL / TLS certificates into the trust store of the iOS simulator.

**Note:** Since iOS 6.1 there seems to be a change in the simulator that prevents the installation of CA
certificates using this method. However, one can create wild-card certificates in Burp (e.g., `*.client.com`) which
 work fine. Still working on getting CA certs to work again.


#### cert install cert_file

Installs the X.509 certificate `cert_file` into the simulator trust store.

**Example:**

    idb > cert install /Users/daniel/test.cert
    [*] Reading and converting certificate...
    [*] Inserting certificate into trust store...
    [*] Operation complete


#### cert uninstall cert_file

Removes the X.509 certificate `cert_file` from the simulator trust store.





**Example:**

    idb > cert uninstall /Users/daniel/test.cert
    [*] Reading and converting certificate...
    [*] Removing exising entry from trust store...
    [*] Operation complete


#### cert list

Lists the subjects of all certificates installed into the trust store.

**Example:**

    idb > cert list
    0  - Subject: /C=PortSwigger/O=PortSwigger/OU=PortSwigger CA/CN=*.client.com
         Details: #<OpenSSL::X509::Certificate subject=/C=PortSwigger/O=PortSwigger/OU=PortSwigger CA/CN=*.client.com, issuer=/C=PortSwigger/ST=PortSwigger/L=PortSwigger/O=PortSwigger/OU=PortSwigger CA/CN=PortSwigger CA, serial=928128029, not_before=2013-04-23 14:35:54 UTC, not_after=2032-09-19 21:04:27 UTC>

####  cert reinstall cert_file

Removes and re-installs the X.509 certificate `cert_file`.

**Example:**

    idb > cert reinstall /Users/daniel/test.cert
    [*] Reading and converting certificate...
    [*] Removing exising entry from trust store...
    [*] Operation complete
    [*] Reading and converting certificate...
    [*] Inserting certificate into trust store...
    [*] Operation complete


### Install Utilities on iDevice

`install` can be used to copy and install various utilities onto an iDevice.

#### install killswitch

Installs iSEC Partners iOS SSL Killswitch which disables certain kinds of certficate pinning and then allows
interception of SSL traffic. If one wants to intercept the Apple store or any other kind of system applications
 that run their own daemon the device needs to be restarted for them to pick up that change. The tool will allow you
 to optionally do that after installation. For more information see:

* https://github.com/iSECPartners/ios-ssl-kill-switch
* http://nabla-c0d3.github.io/blog/2013/08/20/intercepting-the-app-stores-traffic-on-ios/
* http://nabla-c0d3.github.io/blog/2013/08/20/ios-ssl-kill-switch-v0-dot-5-released/

**Example:**

    idb > install killswitch
    [*] Uploading Debian package...
    [*] Installing Debian package...
    [*] Restarting SpringBoard...
    [*] iOS SSL Killswitch installed successfully.
    [**] NOTE: If you need to intercept system applications you should reboot the device.
    Reboot now? (y/n)
    n


#### install dumpdecrypted

Installs Stefan Esser's `dumpdecrypted` dynamic library which, once injected into an app at run time,
 decrypts iOS binaries and writes them to disk.  For more information see:

* https://github.com/stefanesser/dumpdecrypted


**Example:**

    idb > install dumpdecrypted
    [*] Uploading dumpdecrypted library...
    [*] 'dumpdecrypted' installed successfully.


#### install open

Installs Konrad Kramer's `open` (http://moreinfo.thebigboss.org/moreinfo/depiction.php?file=openData) which can be
 used to launch apps on the command line (via SSH). The installation requires `apt-get` to be installed via
 cydia.

**Example:**

    idb > install open
    [*] Checking if apt-get is installed...
    [*] apt-get found.
    [*] Installing open...
