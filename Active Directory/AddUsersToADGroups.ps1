#script that uses a CSV file where the headers are groupnames and the colums contain UPN's to add the users to the groupnames in the collums
$inPutCSV = "H:\DistrilijstenUsers.csv"

#Get the colum names (aka groupnames)
$colums = (Get-Content $inPutCSV)[0] -split ";"
#Import the entire CSV file
$users = Import-Csv -Path $inPutCSV -Delimiter ";"

#Determine the number of colums to determine the number of times the do while loop needs to run
$aantalKolommen = $colums.Count
$i = 0

#Loop through the groups mentioned in the csv file
do {
$i++

$groepNaam = $colums[$i]    
$distriGroepUsers = $users.$groepNaam

#Add each user to the correct distribution group
    foreach ($user in $distriGroepUsers)
        {
            if ($user -ne "" -and $user -ne $null)
                {
                    $user
                    get-aduser -filter {UserPrincipalName -eq $user} | Add-ADPrincipalGroupMembership -MemberOf $groepNaam
                    write-host "$user toegevoegd aan $groepnaam"                  
                }    

        
        }
  

} while ($i -le $aantalKolommen)
