#Script to install application on Citrix in the right order

#Install the Remote Desktop Role and then reboot. After the reboot continue with the rest of the installation. 
import-module servermanager

$RDSInstalled = Get-WindowsFeature | where {$_.installed -eq $true -and $_.name -like "RDS-RD-Server"}
If ($RDSInstalled -eq $null)
    {
        write-host "Now installing the Remote Desktop server role, after that a restart will happen after which the installation will continue" -ForegroundColor Yellow
        write-host "You will need to logon to the server using the same credentials to let the installation continue automatically" -ForegroundColor Yellow
        add-windowsfeature rds-rd-server
        
        #after installation of the RDS server role the server needs to be restarted 
        'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe "d:\genPact_main.ps1"'|out-file "d:\installation.cmd" -Encoding ascii
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce\"
        $script = "d:\installation.cmd"
        new-item -path $registryPath -erroraction silentlycontinue
        new-itemproperty -path $registryPath -name script -value $script -PropertyType string -force
                sleep 10
        Restart-Computer -force
    }

#Put the server into install mode 
write-host "Placing this terminal server into install mode" -ForegroundColor Yellow
change user /install

#Install Internet Explorer and plugins
write-host "Now installing Internet Explorer 11" -ForegroundColor Yellow
Start-Process "D:\Installables\IE11-Windows6.1-x64-en-us.exe" -argumentlist "/passive /norestart" -wait
write-host "Now installing the Internet Explorer Okta Plugin" -ForegroundColor Yellow
start-process "C:\Windows\System32\wscript.exe" -argumentlist "D:\Installables\Unisys_packages\Okta_IE_Plugin_5.2.2\Okta_IE_Plugin_5.2.2_Install.vbs" -wait

#Install the Oracle Client
write-host "Now installing the Oracle 11G client, this will take some time" -ForegroundColor Yellow
Start-Process "C:\Windows\System32\cmd.exe" -argumentlist "/c D:\Installables\Unisys_packages\Oracle11g_Win7\Install.cmd" -wait

#Install Office and Lync
write-host "Now installing Office 2010 and Lync 2010" -ForegroundColor Yellow
start-process "D:\Installables\Office_Prof_Plus_2010w_SP1_x86_English\setup.exe" -argumentlist "/adminfile D:\Installables\Office_Prof_Plus_2010w_SP1_x86_English\citrix_full.msp" -wait
start-process "D:\Installables\Lync_2010_64Bit\LyncSetup.exe" -ArgumentList "/install /silent" -Wait

#start-process "C:\Windows\System32\wscript.exe" -argumentlist "D:\Installables\Unisys_packages\Microsoft_Office_Professional_Plus_2013_ENG\Microsoft_Office_Professional_Plus_2013_ENG_Install.vbs" -wait
#Start-Process "C:\Windows\System32\wscript.exe" -argumentlist "d:\installables\unisys_packages\microsoft_lync_client_2013\Microsoft_lync_client_2013_install.vbs" -wait

#Install Java
write-host "Now installing Java 1.6" -ForegroundColor Yellow
Start-Process "D:\Installables\Java\jre-6u45-windows-x64.exe" -argumentlist "/s" -wait

write-host "Now installing Java 1.7" -ForegroundColor Yellow
Start-Process "D:\Installables\Java\jre-7u80-windows-x64.exe" -argumentlist "/s WEB_JAVA_SECURITY_LEVEL=m" -wait

#write-host "Now installing Java 1.8" -ForegroundColor Yellow
#Start-Process "D:\Installables\Java\jre-8u73-windows-x64.exe" -argumentlist "/s INSTALLCFG=D:\Installables\Java\JRE-8-SilentInstalloptions.cfg" -wait

#Install Adobe Reader
write-host "Now installing Adobe Reader" -ForegroundColor Yellow
start-process "C:\Windows\System32\wscript.exe" -argumentlist "D:\Installables\Unisys_packages\Adobe_Reader_DC_15.009_ENG\Adobe_Reader_DC_15.009_ENG_Install.vbs" -wait

#Install SAP
write-host "Now installing SAP" -ForegroundColor Yellow
Start-Process "C:\Windows\System32\cmd.exe" -argumentlist "/c d:\installables\SAP_GUI_7.2_Win7_unisys\install.cmd" -wait

#Install Winzip
write-host "Now installing Winzip 12" -ForegroundColor Yellow
Start-Process "C:\Windows\System32\wscript.exe" -argumentlist "D:\Installables\Unisys_packages\Winzip12.0\Winzip.vbs" -wait

#Install Citrix VDA
write-host "Now installing the Citrix VDA version 7.8" -ForegroundColor Yellow
start-process "c:\windows\system32\cmd.exe" -ArgumentList "/k D:\Installables\Citrix\VDAServerSetup_7.8.exe /components vda,plugins /noreboot /passive /controllers usflmia-is11.northamerica.delphiauto.net /enable_HDX_3D_PRO /ENABLE_REMOTE_ASSISTANCE /OPTIMIZE" -wait

#Put the server back into execution mode
Change user /execute
write-host "Installation complete, you need to restart te server to make all the settings effective" -ForegroundColor Yellow

write-host "All the applications are installed. Now please reboot the server to finish the configuration Press y to reboot" -ForegroundColor Yellow
$reboot = read-host 
    if ($reboot  -eq "y")
        {
            Restart-Computer -force
        }

#Copy the PSWindowsupdate module and install the windows updates
write-host "Installing Microsoft Updates, this will take some time" -ForegroundColor Yellow
import-module pswindowsupdates
get-wuinstall -IgnoreReboot -AcceptAll