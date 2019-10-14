# PowerShell
Collection of Powershell scripts to do all kinds of maintenance or migration work.

## Active directory folder:
* Displayname naar emailadres:
  * Script to convert displaynames to email adresses and usernames following the convention that was used at the organisation i worked. The displaynames came from the old domain. The user accounts and email addresses were to be created in the new domain.

## Forms folder
The Forms folder contains tools created in powershell but with a graphical user interface. The conversion from .ps1 to .exe is done with the ps2exe tool which you can find on the Microsoft gallery:
https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5

* User Reset tool:
  * A windows forms tool that can be used to remove a user profile from a Windows 7, Windows 10, Windows 2008R2 or Windows 2016 device. Other operating systems might work but these are not tested. 
