Lightsd
=======

This is a node.js thing to control the radio-controlled lights in your home ([klikaanklikuit](http://www.klikaanklikuit.nl/home/) or action or some others).

What you need
----
- A raspberry-pi or something else with a 434MHz transmitter
- An executable that can be called like `./light A 1 on` (ie `kaku` from [lights.zip](https://www.dropbox.com/s/nxdrkuk94w9fpqo/lights.zip?dl=1))
- A [seaport](https://github.com/substack/seaport)@1.7.0 server

How to set it up
----
### On a server accessible from your R-Pi and clients:

Set up a seaport server and make sure it has a static IP or DNS name pointing to it.

### On the Raspberry-Pi:

1. Install libwiringpi
2. Compile the tool for your brand:

    g++ -o kaku kaku.cpp -I/usr/local/include -L/usr/local/lib -lwiringPi

3. Set a `setuid` bit on it if it needs to run as root
4. Copy `config.default.json` to `config.json` and modify the host/port to point to your seaport server, and modify the controller to point to your executable
5. Run `lightsd.js`

### On your client:

Add a `config.json` pointing to your seaport server. You can place this in the same directory as the lightsd installation, or as `~/.config/lights.conf.json` Run the `lights`(or `lights-cli.js`) executable to interface with the server.

Daily Scheduling
------

You can copy the `sun_sched.example.js` file to `sun_sched.js`, the code will be run daily to set times that lights turn on and off. (please keep in mind that the descriptions need to be reasonably unique (everything with the same description is erased when these times are set)).
