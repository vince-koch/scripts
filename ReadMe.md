# Scripts

Just a collection of scripts which make my life easier.  If they help you in any way too, great!

## Powershell

If I'm coding I have at least one terminal window open, usually powershell.  These are some of the scripts I use.  Download what you like, and make sure they are in a path accessible from your powershell session.  Personally I just add them to my **PATH** environment variable.

### ```winterm```
This is a handy script for managing themes inside [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab)

### ```feature [branch-name] [source-branch-name]``` 
Execute this script from the root of a git repository to create a new branch based on an existing branch

### ```vs [version]```
Execute this script from a folder with a Visual Studio solution (*.sln) file.  This script will detect the correct version of Visual Studio based on the solution file itself, and attempt to start Visual Studio from a list of common locations.  You can alternatively specify the version of Visual Studio to open, for example ```vs 2019```



## Userscript / TamperMonkey Script

I use [TamperMonkey](https://www.tampermonkey.net/) browser extension ([Chrome](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/)) to help me fix the things that annoy me about the web.  Copy the RAW url for any of the scripts you would like to install into the following location in the TamperMonkey UI.

*TamperMonkey > Dashboard > Utilities > Install from URL*

### ```CookieMonster.js```
Stop asking me to accept your cookies already - CookieMonster will eat that popup!
