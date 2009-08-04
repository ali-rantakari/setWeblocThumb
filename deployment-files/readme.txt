
setWeblocThumb
-------------------------

DESCRIPTION:

This is a small command-line program for OS X that
assigns custom icons to Web Internet Location (.webloc)
files, displaying a thumbnail of the web page that
they point to.

setWeblocThumb requires Mac OS 10.5 (Leopard) or
later.

Copyright (c) 2009 Ali Rantakari
http://hasseg.org/setWeblocThumb


USAGE:

Run without any arguments to see the usage info.

If you'd like to have this program run automatically
whenever you add .webloc files somewhere (e.g. by
dragging them from your web browser windows), I suggest
using a launch agent. An example launchd configuration
file has been provided, which asks the system to run
setWeblocThumb every time the Desktop folder is modified
(e.g. if some files are added there). Below are some
directions on how to take it into use:

 1. Make a copy of the provided example launch agent     configuration file into the LaunchAgents folder in
    your Library:
    
    $ mkdir -p ~/Library/LaunchAgents
    $ cp "example launchAgents/org.hasseg.setWeblocThumb.desktop.plist" ~/Library/LaunchAgents/.

 2. Edit this file and verify that the paths are correct
    (i.e. replace "your_username" with your actual username,
    or change the paths completely).
 
 3. Tell launchd to load this launch agent:
    
    $ launchctl load ~/Library/LaunchAgents/org.hasseg.setWeblocThumb.desktop.plist

To learn more about launchd, launchctl and launch
agents, please refer to Apple's documentation:

    http://developer.apple.com/MacOsX/launchd.html

Also note that you can achieve similar functionality
(i.e. run setWeblocThumb every time files are added to
a particular folder) by other means as well, such as
folder actions and the Hazel application. I use launchd
simply because folder actions don't quite work for me
(on Mac OS 10.5.7) and I don't own a license to Hazel.










