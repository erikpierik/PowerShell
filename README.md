# PowerShell
Collection of Powershell scripts to do all kinds of maintenance or migration work.

## Active directory folder:
* Displayname naar emailadres:
  * Script to convert displaynames to email adresses and usernames following the convention that was used at the organisation i worked. The displaynames came from the old domain. The user accounts and email addresses were to be created in the new domain.

## Citrix folder:
* ICA Routtrip time:
  * Used to calculate the ICA roundtrip time for a specific issue. This can be used to track performance issues. The cmdlet has to be run from a delivery controller. This script is intended to be used on XenApp 7.x although it might also work on other XenDesktop this is not tested. Sometimes users may report slowness in Citrix but on the server itself nothing can explain this slowness (CPU, Memory and Disk usage are good) then the issue might be something on the network. The ICA roundtrip time shows the latency between the user action (typing a letter or moving the mouse) and that action showing on the screen of the user. 

* RDS, Citrix and application installation:
  * Created for the installation of RDS and Citrix and the neccesary applications on a new Citrix server. In the end the pswindowsupdates module is loaded and the pending updates are installed. The script is handy in places without tools like SCCM, Altiris or Ivanti Automation manager.


## Forms folder:
The Forms folder contains tools created in powershell but with a graphical user interface. The conversion from .ps1 to .exe is done with the ps2exe tool which you can find on the Microsoft gallery:
https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5

* User Reset tool:
  * A windows forms tool that can be used to remove a user profile from a Windows 7, Windows 10, Windows 2008R2 or Windows 2016 device. Other operating systems might work but these are not tested. 
