$groepen = Get-ADGroup -filter {name -like "apl-*"}

foreach ($groep in $groepen)
    {
        $leden = Get-ADGroupMember -Recursive -Identity $groep
        if ($leden.count -eq 0)
            {
                $groepnaam = $groep.name
                write-host "$groepnaam is leeg"
            }
    }