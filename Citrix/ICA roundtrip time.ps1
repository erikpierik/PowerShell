#Script to calculate the ICA Roundtrip time 
#Created by Erik Pierik on 29th of September 2016
<#
.Synopsis
   This CMDlet gets the ICA roundtrip time from a user. This is helpfull to determine if there is a problem on the network when a user reports
   slowness in his session. The cmdlet has to be run from a delivery controller. This script is intended to be used on XenApp 7.x although it might also
   work on other XenDesktop this is not tested. 
.DESCRIPTION
   Sometimes users report slowness in Citrix but on the server itself nothing can explain this slowness (CPU, Memory and Disk usage are good) then the issue
   might be something on the network. The ICA roundtrip time shows the latency between the user action (typing a letter or moving the mouse) and that action 
   showing on the screen of the user. 
.EXAMPLE
   Get-ICARoundTripTimeUser -username samaccountname for example Get-ICARoundTripTimeUser -username bj631q
#>
Function Get-ICARoundTripTimeUser
{
[CmdletBinding()]

Param (
       [parameter(Mandatory=$true)]
       $userName
       
      )

Begin
{
    #For the query user command we only need the samaccountname. For the query of the brokersession we need to add the domain before the user
    #instead of putting a domain in from we use a wildcard so we have to modify the variable to add a * before the username. This way the
    #brokersession can be queried. 
    $userName2 = "*" + $username
    $machineName = "*" + $machineName 
    $loadedSnappins = get-pssnapin 
    #Check if the Citrix snappins are loaded, if not load them
        if (-not $loadedSnappins.tostring().contains("citrix"))
            {
                Add-PSSnapin *citrix*
            }

     
            $sessions = get-BrokerSession -BrokeringUserName $userName2
}
Process 
{
    #sometimes a user might have multiple sessions, to make sure we get the right information for all the sessions we put the sessions in a foreach loop
    foreach ($session in $sessions)
        {
            $substring = $session.MachineName.tostring().IndexOf("\")
            $Server = $session.machinename.tostring().Substring($substring+1)

            $users = query user $userName /server:$server
            $SessionID = $users[1].ToString().substring(42,2)
        

            $roundTrip = Get-CimInstance -ComputerName $server -Namespace root\citrix\euem -ClassName citrix_euem_RoundTrip|where {$_.sessionID -eq $sessionID}
        
            "The ICA rounttrip time for the user " + $userName + " is " + $roundTrip.roundtriptime + " milliseconds on server " + $Server
        
        }
}

#end function
}

<#
.Synopsis
   This CMDlet gets the ICA roundtrip time for all users on a server. This is helpfull to determine if there is a problem on the network when a user reports
   slowness in his session. The cmdlet has to be run from a delivery controller. This script is intended to be used on XenApp 7.x although it might also
   work on other XenDesktop this is not tested. 
.DESCRIPTION
   Sometimes users report slowness in Citrix but on the server itself nothing can explain this slowness (CPU, Memory and Disk usage are good) then the issue
   might be something on the network. The ICA roundtrip time shows the latency between the user action (typing a letter or moving the mouse) and that action 
   showing on the screen of the user. 
.EXAMPLE
   Get-ICARoundTripTimeServer -MachineName hostnameOfXenAppServer for example Get-ICARoundTripTimeServer -machineName usflmia-ts10
#>

Function Get-ICARoundTripTimeServer
{
[CmdletBinding()]

Param (
       [parameter(Mandatory=$true)]
       $machineName = "localhost"
       
      )

Begin
{
    #Check if the snapins are loaded, if not load them first before continuing 
    $loadedSnappins = get-pssnapin 
    #Check if the Citrix snappins are loaded, if not load them
        if (-not $loadedSnappins.tostring().contains("citrix"))
            {
                Add-PSSnapin *citrix*
            }

    $users = query user /server:$machineName 
    $machineName = "*" + $machineName 
                
}
Process 
{
    #Loop through all the users that came up by the query user command. The if statement is to only capture users that are connected through ica
    #we need to use the query User command first because the wmi object only handles the session ID. The get-brokersession command does not provide this
    foreach ($user in $users)
        {
            if ($user.substring(23,1) -eq "i")
                {
                    $SessionID = $user.ToString().substring(42,2)
                    $index = $user.substring(1).indexof(" ")
                    $userName = "*" + $user.ToString().substring(1,$index)
            
                    $session = get-BrokerSession -BrokeringUserName $userName|where {$_.MachineName -like $machineName }
                    $subString = $session.BrokeringUserName.tostring().indexof("\")
                    $userName = $session.BrokeringUserName.ToString().Substring($substring+1)
            
                    $roundTrip = Get-CimInstance -ComputerName $machineName.Substring(1) -Namespace root\citrix\euem -ClassName citrix_euem_RoundTrip|where {$_.sessionID -eq $sessionID}
        
                    "The ICA rounttrip time for the user " + $userName + " is " + $roundTrip.roundtriptime + " milliseconds on server " + $Server
               }
        
        }
}

#end function
}
