# How-To: SSHing via USB

## SSH config
In your `~/.ssh/config` add something like this:

    Host usb
    HostName 127.0.0.1
    Port 2222
    User root
    RemoteForward 8080 127.0.0.1:8080

This will map the hostname "usb" to an SSH connection to localhost on
port 2222 as root. You may wonder "But there is nothing listening on
2222!" Enter `usbmuxd`.


## Install usbmuxd
On OS X as easy as `brew install usbmuxd`
Then you can run `iproxy 2222 22` which will listen on port 2222 (aha!)
and forward all incoming connections via USB to port 22 of the iDevice.


## Using SSH
A simple `ssh usb` will drop you right into an SSH shell (assuming you
have public key auth setup to the iDevice).


## Burping
The SSH config also sets up port forwarding such that any connections to
port 8080 on the iDevice are forwarded to port 8080 locally (on the
laptop). So if you configure the proxy on the iDevice as
"localhost:8080" it will end up in burp (assuming it listens on 8080 on
your laptop).
