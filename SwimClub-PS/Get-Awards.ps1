$SwimClubPath = "C:\Temp"
#Import-Module "$SwimClubPath\Powershell\Swim.Club.psm1" -Force
$date = get-date
$month = $date.Month
$year = [int]($date.ToString('yy'))
if ($Month -ge 7) {
    $season = "$($year).$($year + 1)"
}
else {
    $season = "$($year-1).$($year)"
}
Clear-Host
$seasoninput = Read-Host -Prompt "Which swim season?`nEnter the season (in 'yy.yy' format) and press [Enter], or just [Enter] for season $season"
if (-not $seasoninput) {
    $seasoninput = $season
}
$RootPath = "$($SwimClubPath)\$($seasoninput)"
$DataPath = "$($RootPath)\AwardData"
$ResultsPath = "$($RootPath)\ClubAwards"
Clear-Host
#$cleandata = get-swimmerdata $DataPath -Verbose | Confirm-SwimmerData -verbose
Write-host "Data imported `n"
$awardinput = Read-Host -Prompt "Which Awards to report on?`n[1] Achievement Awards`n[2] Towel Awards`n[3] End Of Season Trophies`nEnter 1, 2 or 3, then press [Enter]"
switch ($awardinput) {
    "1" {
        if (Test-Path "$($ResultsPath)\AwardsList.csv") {
            $importinput = "Y"
        }
        else {
            $importinput = "N"
        }    
        switch ($importinput) {
            "Y" {
                #$newawards = Get-AchievementAwards $cleandata -AwardsListLocation $ResultsPath
                #$updatedawards = Update-AwardsList -NewAwardData $newawards -AwardsListLocation $ResultsPath
            }
            "N" {
                #$newawards = Get-AchievementAwards $cleandata
                #$updatedawards = Update-AwardsList -NewAwardData $newawards
            }
        }
        clear-host
        write-host "The award winners are:"
        write-output $newards
        write-host "`n"
        $writeinput = read-host -prompt "Write these out to file and update the AwardsList (Y or N)?`nEnter Y or N then press [Enter]" 
        if ($writeinput -eq "N") {
            break
        }
        #$clubnightdate = ($cleandata.Values.Values.Date | measure -max).Maximum
        #$newawards | Out-File "$ResultsPath\AchievementAwards\Awards_$clubnightdate.txt"
        if ($importinput -eq "y") {
            #Copy-Item "$($ResultsPath)\AwardsList.csv" -Destination "$($ResultsPath)\_HistoricAwardslists\AwardsList_$($date.tostring('yyMMdd')).csv"
        }
        #$updatedawards | Export-Csv -NoTypeInformation "$($ResultsPath)\AwardsList.csv" -force
        #Invoke-Item "$($ResultsPath)\AchievementAwards\Awards_$clubnightdate.txt"
    }
    "2" {
        clear-host
        $startDate = Read-Host -Prompt "First club night date for the 4 week period?`nEnter the date of the first club night in dd/mm/yy format, the press [Enter]"
        do {
            $Strokename = read-host -prompt "Which stroke to report on?`nEnter Backstroke, Breaststroke, Butterfly or Freestyle, then press [Enter]"
            #$newawards = Get-TowelAwards $cleandata -Stroke $Strokename -FirstClubNight $StartDate -AwardsListLocation $ResultsPath -numberofweeks 4
            clear-host
            write-host "The award winners are:"
            write-output $newards
            write-host "`n"
            $writeinput = read-host -prompt "Write these out to file and update the AwardsList (Y or N)?`nEnter Y or N then press [Enter]" 
            if ($writeinput -eq "N") {
                $newstroke = read-host -prompt "Try another stroke?`nEnter Y or N, then press [Enter]"
            }
            else {
                $newstroke = "N"
            }
        }
        until ($newstroke -eq "N")
        if ($writeinput -eq "N") {
            Break
        }
        if ($newawards) {
            #$newawards | Out-File "$SwimClubPath\ClubAwards\$Season\TowelAwards\$strokename.txt"
            #$updatedawards = Update-AwardsList -NewAwardData $newawards -AwardsListLocation $ResultsPath
            #Copy-Item "$($ResultsPath)\AwardsList.csv" -Destination "$($ResultsPath)\_HistoricAwardslists\AwardsList_$($date.tostring('yyMMdd')).csv"
            #$updatedawards | Export-Csv -NoTypeInformation "$($ResultsPath)\AwardsList.csv" -force
            #Invoke-Item "$($ResultsPath)\TowelAwards\$($strokename).txt"
        }
    }
    "3" {

    }
}
