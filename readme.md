# setWeblocThumb

This is a small command-line program for OS X that assigns custom icons to Web Internet Location (`.webloc`) files, displaying a thumbnail of the web page that they point to.


## Automating It

If you'd like to have this program run automatically whenever you add .webloc files somewhere (e.g. by dragging them from your web browser windows), you can do this in a number of ways. If you have a license to the [Hazel] application, that might be easiest, but other ways are _folder actions (via Automator)_ and _launch agents_, which I'll explain below.

### Launch Agents

A launch agent is a configuration that tells the launchd system to do something (e.g. run `setWeblocThumb`) when something happens (e.g. a file is added to a specific folder).

You can use `setWeblocThumb`'s -a argument to generate launch agents that watch certain paths in your filesystem. For example, run the following command to have it run every time you add files onto your desktop:

    setWeblocThumb -a ~/Desktop

To learn more about `launchd`, `launchctl` and launch agents, please refer to [Apple's documentation][launchd-apple] and the [Wikipedia article][launchd-wikipedia].

### Folder Actions

You can use [Automator] to create a folder action that runs `setWeblocThumb` whenever files are added to a particular folder.

_(Note: these directions are written for Snow Leopard)_

1. Open Automator and select the Folder Action template
1. Select the folder you'd like to attach this action to from the combo box in the upper right-hand corner where it says "Folder Action receives files and folders added to"
1. Drag the Run Shell Script action from the list in the left (it's under Utilities) to the action area on the right
1. Select Pass input: as arguments in the action's settings
1. Type the following into the shell script action's text field:

        /usr/local/bin/setWeblocThumb "`dirname \"$1\"`"

1. Save

[Hazel]: http://www.noodlesoft.com/hazel.php
[launchd-wikipedia]: http://en.wikipedia.org/wiki/Launchd
[launchd-apple]: http://developer.apple.com/MacOsX/launchd.html
[Automator]: http://www.apple.com/macosx/what-is-macosx/apps-and-utilities.html#automator


## License

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.
