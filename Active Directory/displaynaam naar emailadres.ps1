$DisplaynamesMdb = import-csv "Z:\displaynames.csv"
$users = $DisplaynamesMdb.name 

foreach ($user in $users)
    {
    $voorLetter = $user.Substring(0,1)
        if ($user.Contains(" van de "))
            { 
                $positie = $user.IndexOf(" van de ")
                $achternaam = $user.substring($positie + 8)
                $mail = $voorletter + "vande" + $achternaam + "@pierik.it"
                $userName = $voorletter + "vande" + $achternaam
                $mail = $mail.tolower()
                $username = $username.tolower()
            }
        elseif ($user.Contains(" van der "))
            { 
                $positie = $user.IndexOf(" van der ")
                $achternaam = $user.substring($positie + 9)
                $mail = $voorletter + "vander" + $achternaam + "@pierik.it"
                $userName = $voorletter + "vander" + $achternaam
                
            }
        elseif ($user.Contains(" van den "))
            {
                $positie = $user.IndexOf(" van den ")
                $achternaam = $user.substring($positie + 9)
                $mail = $voorletter + "vanden" + $achternaam + "@pierik.it"
                $userName = $voorletter + "vanden" + $achternaam
                
            }
        elseif ($user.contains(" van ")) 
            { 
                $positie = $user.IndexOf(" van ")
                $achternaam = $user.substring($positie + 5)
                $mail = $voorletter + "van" + $achternaam + "@pierik.it"
                $userName = $voorletter + "van" + $achternaam
                
            }
        elseif ($user.contains(" de "))
            { 
                $positie = $user.IndexOf(" de ")
                $achternaam = $user.substring($positie + 4)
                $mail = $voorletter + "de" + $achternaam + "@pierik.it"
                $userName = $voorletter + "de" + $achternaam
            }
        else 
            {
            $positie = $user.indexof(" ")
            $achternaam = $user.substring($positie + 1)
            $mail = $voorletter + $achternaam + "@pierik.it"
            $userName = $voorletter + $achternaam
            }

    $mail = $mail.tolower()
    $username = $username.tolower()
    
    $username + " , " + $mail |out-file "Z:\usersNieuweInlog.cvs" -Append
    
    $mail = $null
    $username = $null
    $positie = $null
    }