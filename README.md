# Introduction #
Every of us knows it... you have to give remote control to some unknown person, you login with your admin credentail, maybe even domain admin, so that person can do basically everything now behind your back. Or you use an unprivileged account for that remote control, but the questen if he has enough privileges to do basically anything.

Here my Tool enters the game. You may use an uprevileged account but you can allways type your credentail into the application, which are not redable by the user and give him some of your power, to for exaple start and elevated shell or start an exe.

Many thanks to Brent and his script(https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Script-410ef9df) i used to encrypt and decrypt settings so noone can change them, or if changed the program will be brocken, but you at least know who broke it ^-^.

# Using the source code #
You may be interest in using the source code, you might need to change some values in the script. You need to alter the global vars. You will later need those vars to encrypt and decrypt settings to save them in the ini files. You might want to enter those ecrypted setting directly in the setup.ps1 so all you need to do is run setup ps1 and you will no need to alter the ini manualy.
But be careful I had to replace $PSScriptRoot with something else which means your working directory has to be the same as of the script. I have used VS Code and had errors when I just pressed F5, please take this note.
# Setup #
There is a setup.exe which will create directories aswell as config files. Don't move the exe, the exe is bound to its initial location because it need its config files.

After the setup you should be able to statrt the Security-App.exe, but please dont move it arround since it depends of the config file location, just make a shortcut. Also never start it as admin because it would break the concept.
## Requiments ##
There is some needed software as well as optional software that needs to be installed for the application in order to work properly.

So what do we need?
- PSReadLine which is mostly already installed on new hosts if i remember right iits installed at PowerShell 5.0 upwards. We need it for advanced PS logging.
- Clink for CMD. Is needed becasue the normal CMD doesent have any kind of persistent history. Once closed its gone.
- Chocolatey, we need it in order to be able to install Clink.
- The Acrive Directory Module for PowerShell. You might need it if you have a domain joined host and then you can provide AD or local credentails, else its only allowed to use local credentails. We need it to check if your in the admin group, the Domain admin group you enter in the settings part or in  the  local Adminostrators group.
### Install ###
Execute setup.exe and watch it running, no im making jokes, you might need to enter some infos as well as decide to install optional software.
### Uninstall ###
Execute uninstall.exe and the tool will destroy itself. Ok i couldnt find a way to delete the uninstaller it self, sou you still have to delete the uninstaller.
# Usage #
To use and compile it yourself  you need to change the values in the global var region. And use the Decrypt/Encrypt script to create the setting entries.
### Login ###
![Login GUI](https://github.com/seyo-IV/PowerShell-Security-App/blob/master/images/Login.PNG)

Obivious its a login screen. Default login credentails are (Warning its case sensitive!) username/password for the normal user and admin/admin for admin.
### Operations ###
![Operations GUI](https://github.com/seyo-IV/PowerShell-Security-App/blob/master/images/Operations.PNG)

- We got here PowerShell, CMD and the Server Manager which can all be started with the "as Admin" checkbox to be started as admin but this only works if you are an admin or you provide AD or Local Admin credentails. Active Directory is only the query function where you can search for ad-objects but you cant alter them.
- As mentioned above you can provide credentail so the tools or applications are initialized with elevated rights. Credentails can be either local or domain. Youe the combobox for that.
- With "Open" you can either open the file with a file dialog or you can type the path to the application yourself.
- With "Check Local Admin" you can check if the provided credentaisl are those of an admin or if the login user is an admin yourself.
### Output ###
![Output GUI](https://github.com/seyo-IV/PowerShell-Security-App/blob/master/images/Output.PNG)

Here lands the output of your usage of the tools. But you can also load the logs of the current day/session.
## Admin area ##
### Settings ###
![Settings GUI](https://github.com/seyo-IV/PowerShell-Security-App/blob/master/images/Settings.PNG)

This are is reserved for admin only. So provide admin credentails on login you can access it. Once you set setings the app will close and you have to reopen it.

For security reasons i decided to hash the settings so noone can just read the ini and change username/password. The settings are set all at once but if you leave a textbox blank the old value is taken. After setting the settings you need to restart the App.

To see the current locaded settings press "Get-Values".
