Function Get-SiteCode {
    [cmdletBinding()]
    param (
      $SMSProvider
    )
    $wqlQuery = 'SELECT * FROM SMS_ProviderLocation'
    $a = Get-WmiObject -Query $wqlQuery -Namespace 'root\sms' -ComputerName $SMSProvider
    $a | ForEach-Object {
      if($_.ProviderForLocalSite)
      {
        $SiteCode = $_.SiteCode
      }
    }
    return $SiteCode
  }
  Function Add-NodeToConfigMgrCollection {
    [cmdletBinding()]
  
    param (
      $Node,
      $CollectionID,
      $SiteCode,
      $SMSProvider
    )
  
    $Device = Get-WmiObject -ComputerName $SMSProvider -Class SMS_R_SYSTEM -Namespace root\sms\site_$SiteCode -Filter "Name = '$Node'"
    $objColRuledirect = [WmiClass]"\\$SMSProvider\ROOT\SMS\site_$($SiteCode):SMS_CollectionRuleDirect"
    $objColRuleDirect.psbase.properties['ResourceClassName'].value = 'SMS_R_System'
    $objColRuleDirect.psbase.properties['ResourceID'].value = $Device.ResourceID
  
    $MC = Get-WmiObject -Class SMS_Collection -ComputerName $SMSProvider -Namespace "ROOT\SMS\site_$SiteCode" -Filter "CollectionID = '$CollectionID'"
    $InParams = $mc.psbase.GetMethodParameters('AddMembershipRule')
    $InParams.collectionRule = $objColRuledirect
    $R = $mc.PSBase.InvokeMethod('AddMembershipRule', $inParams, $Null)
  }
  Function Invoke-PolicyDownload {
    [CmdletBinding()]
    param(
      [Parameter(Position=0,ValueFromPipeline=$true)]
      [System.String]
      $ComputerName=(get-content env:computername) #defaults to local computer name
    )
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000021}' -ComputerName $ComputerName -ErrorAction SilentlyContinue | Out-Null
    #Trigger machine policy download
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000022}' -ComputerName $ComputerName -ErrorAction SilentlyContinue | Out-Null
    #Trigger Software Update Scane cycle
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000113}' -ComputerName $ComputerName -ErrorAction SilentlyContinue | Out-Null
    #Trigger Software Update Deployment Evaluation Cycle
    Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule '{00000000-0000-0000-0000-000000000114}' -ComputerName $ComputerName -ErrorAction SilentlyContinue | Out-Null
  
  }
  Function Get-ConfigMgrSoftwareUpdateCompliance {
    [CmdletBinding()]
    param(
      [Parameter(Position=0,ValueFromPipeline=$true)]
      [System.String]
      $ComputerName=(get-content env:computername) #defaults to local computer name
    )
    Invoke-PolicyDownload -ComputerName $ComputerName;
    do {
      Start-Sleep -Seconds 30
      Write-Output "Checking Software Updates Compliance on [$ComputerName]"
  
      #check if the machine has an update assignment targeted at it
      $global:UpdateAssigment = Get-WmiObject -Query 'Select * from CCM_AssignmentCompliance' -Namespace root\ccm\SoftwareUpdates\DeploymentAgent -ComputerName $ComputerName -ErrorAction SilentlyContinue ;
  
      Write-Output $UpdateAssigment
  
      #if update assignments were returned check to see if any are non-compliant
      $IsCompliant = $true
  
      $UpdateAssigment | ForEach-Object{
        #mark the compliance as false
        if($_.IsCompliant -eq $false -and $IsCompliant -eq $true){$IsCompliant = $false}
      }
      #Check for pending reboot to finish compliance
      $rebootPending = (Invoke-WmiMethod -Namespace root\ccm\clientsdk -Class CCM_ClientUtilities -Name DetermineIfRebootPending -ComputerName $ComputerName).RebootPending
  
      if ($rebootPending)
      {
        Invoke-WmiMethod -Namespace root\ccm\clientsdk -Class CCM_ClientUtilities -Name RestartComputer -ComputerName $ComputerName
        do {'waiting...';start-sleep -Seconds 5}
        while (-not ((get-service -name 'SMS Agent Host' -ComputerName $ComputerName).Status -eq 'Running'))
  
      }
      else {
        Write-Output 'No pending reboot. Continue...'
      }
    }
    while (-not $IsCompliant)
  }
  
  #Start Updating one Secondary Node at a time
  
  $SiteCode = Get-SiteCode -SMSProvider $SMSProvider
  $i = 0
  foreach ($SecondaryReplica in $SecondaryReplicaServer) {
    if (-not ($AlreadyPatched -contains $SecondaryReplica.Split('\')[0])) {
      try {
        $i++
        Write-Verbose "Patching Server round $i = $($SecondaryReplica.Split('\')[0])"
  
        #Add current secondary node to ConfigMgr collection to receive its updates
        Add-NodeToConfigMgrCollection -Node $SecondaryReplica.Split('\')[0] -SiteCode $SiteCode -SMSProvider $SMSProvider -CollectionID $CollectionID -Verbose
  
        Start-Sleep -Seconds 60
        Invoke-policydownload -computername $SecondaryReplica.Split('\')[0]
  
        Start-Sleep -Seconds 120
        Invoke-policydownload -computername $SecondaryReplica.Split('\')[0]
  
        Start-Sleep -Seconds 120
        #Check if all updates have been installed and server finished rebooting
        Write-Output 'Applying updates now'
        Get-ConfigMgrSoftwareUpdateCompliance -ComputerName $SecondaryReplica.Split('\')[0]
  
        $AlreadyPatched += $SecondaryReplica.Split('\')[0]
      }
      catch {
        Write-Error $_
      }
    }
    else {
      Write-Verbose "$($SecondaryReplica.Split('\')[0]) has already been patched. Skipping."
    }
  }
  
  # fail over to one of the secondary nodes and update the primary node, after that, fail over again to the original primary node
  
  Switch-SqlAvailabilityGroup -Path SQLSERVER:\Sql\$(Get-Random -InputObject $SecondaryReplicaServer)\Default\AvailabilityGroups\$AvailabilityGroupName -Verbose
  Add-NodeToConfigMgrCollection -Node $PrimaryReplicaServer.Split('\')[0] -SiteCode $SiteCode -SMSProvider $SMSProvider -CollectionID $CollectionID -Verbose
  
  Start-Sleep -Seconds 60
  Invoke-PolicyDownload -computername $PrimaryReplicaServer.Split('\')[0]
  
  Start-Sleep -Seconds 90
  Invoke-PolicyDownload -computername $PrimaryReplicaServer.Split('\')[0]
  
  Start-Sleep -Seconds 90
  #Check if all updates have been installed and server finished rebooting
  Write-Output 'Applying updates now'
  Get-ConfigMgrSoftwareUpdateCompliance -ComputerName $PrimaryReplicaServer.Split('\')[0]
  
  
  #If the primary node is finished updating, fail over again to the Primary
  Switch-SqlAvailabilityGroup -Path SQLSERVER:\Sql\$PrimaryReplicaServer\Default\AvailabilityGroups\$AvailabilityGroupName -Verbose