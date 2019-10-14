#This form was created using POSHGUI.com  a free online gui designer for PowerShell
#Het script is verder gemaakt door Erik Pierik op 13-11-2018

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#Functies om de acties daadwerkelijk uit te voeren
#Verwijder het geselecteerde profiel
function VerwijderProfiel {
    $script:ProfielPad = $profielen.selectedItem
          
    #controleer of de gebruiker een actieve sessie heeft, wanneer dat het geval is kan het profiel niet worden verwijderd
    $script:loggedOnUsers = Get-WmiObject -Class win32_computersystem -ComputerName $script:computerName |select -expandproperty username
    If ($script:loggedOnUsers -ne $null)  
        {
            $script:loggedOnUsers = Get-WmiObject -Class win32_computersystem -ComputerName $computerName |select -expandproperty username
            [System.Windows.Forms.MessageBox]::Show("De gebruiker $script:ProfielPad is nog ingelogd laat de gebruiker uitloggen en klik op OK om het nogmaals te proberen","Error",[System.Windows.Forms.MessageBoxButtons]::OK)
			$form.dispose()
			$form.close()
			LaadForm
        }  

    #om lokaal een backup t$script:ProfielPad.Replace("c:\Users\","")e hebben van het profiel moet eerst het huidige profiel worden hernoemd
    $script:remotePath = $script:ProfielPad.Replace("C:\", "\\$script:computername\c$\")
    $script:extention = ".old"
    $script:i = 0

    #Wanneer er al eerder een profiel reset is uitgevoerd en er al een .old map aanezig is zal er een andere extentie worden gekozen. 
    while ((Test-Path $script:remotePath$extention) -eq $true) 
        {
            $i++
            $script:extention = $Script:extention + $script:i                
        }
    $script:username = $script:ProfielPad.Replace("C:\Users\", "")
	Try
		{
			#Hernoem de profielmap naar de hierboven gevonden extentie
			Rename-Item $script:remotePath $script:userName$script:extention

			#verwijder vervolgens het profiel via WMI
			Get-WmiObject -Class win32_userprofile -ComputerName $script:computerName | where {$_.LocalPath -eq $script:ProfielPad } | foreach {$_.Delete()}
			[System.Windows.Forms.MessageBox]::Show("Het profiel van gebruiker $script:username is verwijderd, de gebruiker mag opnieuw inloggen","Success",[System.Windows.Forms.MessageBoxButtons]::OK)
		}
	Catch 
		{
			[System.Windows.Forms.MessageBox]::Show("Er is iets mis gegaan bij het verwijderen van het profiel zie de logfile in de %temp% map voor meer informatie","Error",[System.Windows.Forms.MessageBoxButtons]::OK)
			$error |out-file $ENV:Temp\UserResetError.log -encoding ascii
		}
	}
	

#Controleer of de werkplek aan staat
function checkConnection {
    $script:computerName = $ComputerNa.lines

    #Controleer of de werkplek is ingeschakeld ga alleen verder wanneer dat het geval is. 
    if ((Test-Connection $computerName -Count 1 -Quiet -EA 0) -eq $false)    {
        #[System.Windows.Forms.MessageBox]::Show("De werkplek $script:computerName is uitgeschakeld/niet via het netwerk benaderbaar, herstel de verbinding en klik op OK om het nog een keer te proberen")
        $oReturn=[System.Windows.Forms.MessageBox]::Show("De werkplek $script:computerName is uitgeschakeld/niet via het netwerk benaderbaar, herstel de verbinding en klik op Opnieuw om het nog een keer te proberen of cancel om het formulier weer te openen","Error",[System.Windows.Forms.MessageBoxButtons]::RetryCancel)
    
	    switch ($oReturn){
	        "Retry" {
	            checkConnection
	        }
	        "Cancel" {
                #Open het form opnieuw
                $form.dispose()
                $form.close()
                LaadForm
            }
    }
    }
    else {
        Get_Users
    }

}

#Haal de profielen op van de werkplek
function Get_Users {
    $script:computerName = $ComputerNa.lines
	$script:usersToReset = Get-WmiObject -Class win32_userprofile -ComputerName $computerName | where {$_.localpath -notlike "C:\Windows*" }
    
    $form.dispose()
    $form.close()
    
    #Open het form opnieuw
    LaadForm
    }


#region begin GUI{ 
function LaadForm {
$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '400,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false
$form.Controls

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Computernaam:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 20
$Label1.location                 = New-Object System.Drawing.Point(10,9)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$ComputerNa                      = New-Object system.Windows.Forms.TextBox
$ComputerNa.lines				 = $script:computerName		 
$ComputerNa.multiline            = $false
$ComputerNa.width                = 200
$ComputerNa.height               = 20
$ComputerNa.location             = New-Object System.Drawing.Point(136,9)
$ComputerNa.Font                 = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Profielen:"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 20
$Label2.location                 = New-Object System.Drawing.Point(10,45)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$profielen                       = New-Object system.Windows.Forms.ListBox
if ($usersToReset.localPath -ne $null)
    {
        $profielen.items.AddRange($usersToReset.localPath)
    }

$profielen.width                 = 200
$profielen.height                = 250
$profielen.location              = New-Object System.Drawing.Point(136,45)
$profielen.Font                  = "Microsoft Sans Serif,10"

$zoekProfielen                         = New-Object system.Windows.Forms.Button
$zoekProfielen.text                    = "Zoek Profielen"
$zoekProfielen.width                   = 80
$zoekProfielen.height                  = 40
$zoekProfielen.location                = New-Object System.Drawing.Point(136,300)
$zoekProfielen.Font                    = 'Microsoft Sans Serif,10'
$zoekProfielen.add_Click({checkConnection})

$VerwijderProfiel                         = New-Object system.Windows.Forms.Button
$VerwijderProfiel.text                    = "Verwijder Profiel"
$VerwijderProfiel.width                   = 80
$VerwijderProfiel.height                  = 40
$VerwijderProfiel.location                = New-Object System.Drawing.Point(220,300)
$VerwijderProfiel.Font                    = 'Microsoft Sans Serif,10'
$VerwijderProfiel.add_Click({VerwijderProfiel})

$Form.controls.AddRange(@($ListView1,$ComputerNa,$Label1,$Label2,$profielen,$zoekProfielen,$VerwijderProfiel))

#region gui events {
#endregion events }

#endregion GUI }


#Write your logic code here

[void]$Form.ShowDialog()
}

#####
#Variable voor lijst met profielen vullen met iets om zo een foutmelding bij het starten te voorkomen
#$usersToReset = "."
#$usersToReset | Add-Member -TypeName localpath -Value "." 
#$usersToReset | Add-Member localPath profielen
#Formulier aanroepen
laadForm