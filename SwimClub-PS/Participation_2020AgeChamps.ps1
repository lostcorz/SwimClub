$2020 = Get-SwimmerData -csvPath "C:\Users\PRCAClub\MeetData\2019-20\AwardData"
$members = Import-Csv "C:\Users\PRCAClub\Documents\2019-20\ClubChampionReferences\SwimCentralMemberExport.csv"
$Swimmers = @()

foreach ($swmr in $2020.Keys) {
    $split = $swmr.Split(',')
    $first = $split[1].Trim()
    $second = $split[0].Trim()
    $swmrrecord = $members | where {($_."First Name").Trim() -eq $first -and ($_."Last Name").Trim() -eq $second} 
    $obj = New-Object PSObject
    $obj | Add-Member -MemberType NoteProperty -Name "Swimmer" -Value $swmr
    $obj | Add-Member -MemberType NoteProperty -Name "Gender" -Value $swmrrecord.Gender
    $obj | Add-Member -MemberType NoteProperty -Name "Meets" -Value ($2020[$swmr].Values.Date | select -Unique).count
    $obj | Add-Member -MemberType NoteProperty -Name "MemberType" -Value $swmrrecord."Membership Name"
    $obj | Add-Member -MemberType NoteProperty -Name "Award" -Value $null
    $Swimmers += $obj
}

$swimmers | Export-Csv "C:\tmp\2020Swimmers.csv" -NoTypeInformation

#___________________________________________________________________________________________________________________________________


$2020 = Get-SwimmerData -csvPath "C:\Users\PRCAClub\MeetData\2019-20\AwardData"
$members = Import-Csv "C:\Users\PRCAClub\Documents\2019-20\ClubChampionReferences\SwimCentralMemberExport.csv"
$csv = Import-Csv C:\Users\PRCAClub\Documents\2019-20\ClubChampionReferences\eventlist2.csv -Header (1..13)
$AgeChampDate = "200320"

$memberList = @()
foreach ($mbr in $members) {
    $swimmer = "$(($mbr."Last Name").Trim()), $(($mbr."First Name").Trim())"
    $obj = New-Object psobject
    $obj | Add-Member -MemberType NoteProperty -Name "Swimmer" -Value $swimmer
    $swimmerdetails = Get-SwimmersCategory -SwimmersName $Swimmer -ClubNightDate $AgeChampDate -MemberData $members -Verbose
    $obj | Add-Member -MemberType NoteProperty -Name "Category" -Value  "$($swimmerdetails['Age'])$($swimmerdetails['Gender'])"
    $memberList += $obj
}

$Categories = @{}
foreach ($evt in $csv.13) {
    $index = ([regex]::Match($evt, '[1245]+[50]+[" "0]+[BFI]')).index
    $length = $evt.Length - $index
    $rawEvent = $evt.Substring($index, $length)
    $event = ($rawEvent.split(" ")[1] + $rawEvent.split(" ")[0])
    $rawEventType = $evt.split(" ")
    if ($rawEventType[2] -eq "&" -and $rawEventType[3] -eq "Under") {
        $ages = (($rawEventType[1])..5)
    }
    elseif ($rawEventType[2] -eq "&" -and $rawEventType[3] -eq "Over") {
        $ages = (($rawEventType[1])..15)
    }
    elseif ($rawEventType[1] -match "-") {
        $ages = ($rawEventType[1]).split("-")
    }
    elseif ($rawEventType[2] -like "Year*") {
        $ages = $rawEventType[1]
    }
    foreach ($age in $ages) {
        $category = "$age$($rawEventType[0])"
        if (-not $Categories[$Category]) {
            $Categories[$Category] = @()
        }
        $Categories[$Category] += $event
    }
}
$totaleventlist = @()
foreach ($val in $Categories.Values) {
    foreach ($i in $val) {
        if ($i -notin $totaleventlist) {
            $totaleventlist += $i
        }
    }
}
$outputarray = @()
foreach ($category in $Categories.Keys) {
    write-host "Processing $category"
    $catSwimmers = $memberList | where {$_.Category -eq $category -and $_.Swimmer -in $2020.Keys}
    write-host "Processing $($catSwimmers.Count) Swimmers in $category"
    foreach ($Swimmer in $catSwimmers) {
        write-host "Processing $($swimmer.Swimmer)"
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Swimmer" -Value $Swimmer.Swimmer
        $obj | Add-Member -MemberType NoteProperty -Name "Category" -Value $category
        $obj | Add-Member -MemberType NoteProperty -Name "CategoryPlace" -Value $null
        $obj | Add-Member -MemberType NoteProperty -Name "TotalPoints" -Value $null
        foreach ($i in ($totaleventlist | sort)) {
            $obj | Add-Member -MemberType NoteProperty -Name $i -Value $null
        }
        foreach ($evt in $Categories[$category]) {
            if ($evt -in $2020[$swimmer.Swimmer].Keys) {
                Write-Host "processing $evt for $($swimmer.swimmer)"
                $stroketimes = @()
                foreach ($i in ($2020[$swimmer.swimmer][$evt].time | Where-Object {$_ -ne 'DQ'})) {
                    $stroketimes += [timespan]::ParseExact($i, $timepatterns, [cultureinfo]::CurrentCulture)
                }
                $fastesttime = ($stroketimes | Measure-Object -Minimum).Minimum
                $obj.$evt = $fastesttime
            }
            elseif ($evt -like "*25" -and ($evt.Replace("25","50")) -in $2020[$swimmer.Swimmer].Keys) {
                Write-Host "processing $evt for $($swimmer.swimmer)"
                $stroketimes = @()
                foreach ($i in ($2020[$swimmer.swimmer][$evt].time | Where-Object {$_ -ne 'DQ'})) {
                    $stroketimes += ([timespan]::ParseExact($i, $timepatterns, [cultureinfo]::CurrentCulture) / 2)
                }
                $fastesttime = ($stroketimes | Measure-Object -Minimum).Minimum
                $obj.$evt = $fastesttime
            }
        }
        $outputarray += $obj
    }
    $results = $outputarray | where {$_.Category -eq $category}
    foreach ($evt in $Categories[$category]) {
        $orderedresults = $results | Where {$_.$evt -ne $null} | Sort $evt
        if ($orderedresults) {
            if ($orderedresults.count -ge 1) {
                foreach ($i in (1..$orderedresults.count)) {
                    if ($i -eq 1) {
                        $orderedresults[0].$evt = [int]5
                    }
                    elseif ($i -eq 2) {
                        $orderedresults[1].$evt = [int]3
                    }
                    elseif ($i -eq 3) {
                        $orderedresults[2].$evt = [int]1
                    }

                    else {
                        $orderedresults[$i-1].$evt = [int]0
                    }
                }
            }
            else {
                $orderedresults[0].$evt = [int]5
            }
        }
    }
    foreach ($swimmer in $results)  {
        $swimmerspoints = 0
        foreach ($evt in $Categories[$category]) {
            $swimmerspoints += $swimmer.$evt
        }
        $swimmer.TotalPoints = $swimmerspoints
    }
    $results = $outputarray | where {$_.Category -eq $category} | sort TotalPoints -Descending
    if ($results) {
        if ($results.count -ge 1) {    
            foreach ($i in (1..$results.count)) {
                $results[$i-1].CategoryPlace = $i
            }
        }
        else {
            $results[0].CategoryPlace = 1
        }
    }
}
$outputarray | sort Category, CategoryPlace | export-csv "C:\Users\PRCAClub\Google Drive\Pine Rivers Community Aquatics\2019 - 2020 Season\ClubAwards\Trophies\AgeChamps.csv" -NoTypeInformation