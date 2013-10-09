# idb Usage

idb can be used in two ways as an interactive shell or as a command line utility which executes a single command.
DSDUU

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

## Usage with iDevice

To use idb with an iDevice run it, e.g.,  with the following command:

    ruby idb.rb --device --hostname localhost --port 2222 --username root --password alpine


## Usage with Simulator

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

## Specifying the Command on the Command Line

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



