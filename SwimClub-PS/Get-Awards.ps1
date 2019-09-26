# PATH VARIABLES
#-------------------------------------------
# Path To Meet Manager CSV Exports
$SwimDataPath = "C:\Temp\SwimClub"
#-------------------------------------------
# Path to Google Drive
$GoogleDrivePath = "C:\Temp\SwimClub\Google"
#-------------------------------------------
# Path to Club Champion Reference Times

#-------------------------------------------

# Import the Module
Import-Module "$SwimDataPath\Powershell\Swim.Club.psm1" -Force

# Create an array of the strokes to use in the Towel & 25m Improvement
$strokearray = "Backstroke", "Breaststroke", "Butterfly", "Freestyle"

# Get the date and workout the current season
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

#Ask if the current season is to be used?
do {
    $seasoninput = Read-Host -Prompt "Swim season $($season)?`nPress [Enter] for season $season or enter the season (in 'yy.yy' format) and press [Enter]"
    if (-not $seasoninput) {
        $seasoninput = $season
    }
}
until ($seasoninput -like "??.??")

#Use the season to finalise paths for results and data
$DataPath = "$($SwimDataPath)\$($seasoninput)\AwardData"
$ResultsPath = "$($GoogleDrivePath)\$($seasoninput)\ClubAwards"

#-------------------------------------------
# Load the season data
$cleandata = get-swimmerdata $DataPath -Verbose | Confirm-SwimmerData -verbose
Clear-Host
Write-host "Data imported `n"
#-------------------------------------------
# Main award menu
do {
    do {
        $awardinput = Read-Host `
            -Prompt "Which Awards to report on?`n[1] Achievement Awards`n[2] Towel Awards`n[3] End Of Season Trophies`nEnter 1, 2 or 3, then press [Enter]"
    }
    until ($awardinput -in (1..3))
    switch ($awardinput) {
        #-------------------------------------------
        # Achievement Awards
        "1" {
            if (Test-Path "$($ResultsPath)\AwardsList.csv") {
                $importinput = "Y"
            }
            else {
                $importinput = "N"
            }    
            switch ($importinput) {
                "Y" {
                    $newawards = Get-AchievementAwards $cleandata -AwardsListLocation $ResultsPath
                    $updatedawards = Update-AwardsList -NewAwardData $newawards -AwardsListLocation $ResultsPath
                }
                "N" {
                    $newawards = Get-AchievementAwards $cleandata -Verbose
                    $updatedawards = Update-AwardsList -NewAwardData $newawards
                }
            }
            clear-host
            if ($newawards) {
                write-host "The award winners are:"
                foreach ($swmr in $newawards) {
                    write-host $swmr
                }
                write-host "`n"
                $writeinput = read-host -prompt "Write these out to file and update the AwardsList (Y or N)?`nEnter Y or N then press [Enter]" 
                if ($writeinput -eq "N") {
                    break
                }
                $clubnightdate = ($cleandata.Values.Values.Date | Measure-Object -max).Maximum
                if (-not (Test-Path "$ResultsPath\AchievementAwards")) {
                    New-Item -Name "AchievementAwards" -ItemType Directory -Path $ResultsPath
                }
                $newawards | Out-File "$ResultsPath\AchievementAwards\Awards_$clubnightdate.txt"
                if ($importinput -eq "y" -and (-not(Test-Path "$ResultsPath\_HistoricAwardslists"))) {
                    New-Item -Name "_HistoricAwardslists" -ItemType Directory -Path $ResultsPath
                    Copy-Item "$($ResultsPath)\AwardsList.csv" -Destination "$($ResultsPath)\_HistoricAwardslists\AwardsList_$($date.tostring('yyMMdd')).csv"
                }
                elseif ($importinput -eq "y") {
                    Copy-Item "$($ResultsPath)\AwardsList.csv" -Destination "$($ResultsPath)\_HistoricAwardslists\AwardsList_$($date.tostring('yyMMdd')).csv"
                }
                $updatedawards | Export-Csv -NoTypeInformation "$($ResultsPath)\AwardsList.csv" -force
                clear-host
                Write-Host "Achievement Award report was written to $($ResultsPath)\AchievementAwards\Awards_$clubnightdate.txt"
            }
            do {
                $returnmenu = Read-Host `
                    -Prompt "Return to Award Menu?`nType Y or N and press [Enter]"
            }
            until ($returnmenu -in ('Y','N'))
        }
        #-------------------------------------------
        # Towel Awards
        "2" {
            clear-host
            do {
                $startDate = Read-Host -Prompt "First club night date for the 4 week period?`nEnter the date of the first club night in dd/mm/yy format, then press [Enter]"
            }
            until ($startDate -like "??/??/??")
            do {
                do {
                    $strokeinput = read-host -prompt "Which stroke to report on?`n[1] Backstroke`n[2] Breaststroke`n[3] Butterfly`n[4] Freestyle`nEnter 1, 2, 3 or 4, then press [Enter]"
                }
                until ($strokeinput -in (1..4))
                $Strokename = $strokearray[$strokeinput - 1]
                $newawards = Get-TowelAwards $cleandata -Stroke $Strokename -FirstClubNight $StartDate -AwardsListLocation $ResultsPath -numberofweeks 4
                if (-not $newawards) {
                    clear-host
                    write-host "There are no award winners for $strokename"
                    write-host "`n"
                    $writeinput = "N"
                }
                else {
                    clear-host
                    write-host "The award winners are:"
                    foreach ($swmr in $newawards) {
                        write-host $swmr
                    }
                    write-host "`n"
                    $writeinput = read-host -prompt "Write these out to file and update the AwardsList (Y or N)?`nEnter Y or N then press [Enter]" 
                }
                if ($writeinput -eq "N") {
                    $newstroke = read-host -prompt "Try another stroke?`nEnter Y or N, then press [Enter]"
                }
                else {
                    $newstroke = "N"
                }
            }
            until ($newstroke -eq "N")
            if ($writeinput -eq "Y") {
                if (-not(Test-Path "$($ResultsPath)\TowelAwards")) {
                New-Item -Name "TowelAwards" -ItemType Directory -Path $ResultsPath
                }
                $newawards | Out-File "$ResultsPath\TowelAwards\$strokename.txt"
                $updatedawards = Update-AwardsList -NewAwardData $newawards -AwardsListLocation $ResultsPath
                if (-not(Test-Path "$($ResultsPath)\_HistoricAwardslists")) {
                    New-Item -Name "_HistoricAwardslists" -ItemType Directory -Path $ResultsPath
                }
                Copy-Item "$($ResultsPath)\AwardsList.csv" -Destination "$($ResultsPath)\_HistoricAwardslists\AwardsList_$($date.tostring('yyMMdd')).csv"
                $updatedawards | Export-Csv -NoTypeInformation "$($ResultsPath)\AwardsList.csv" -force
                clear-host
                Write-Host "Towel Award report was written to $($ResultsPath)\TowelAwards\$($strokename).txt"
            }
            do {
                $returnmenu = Read-Host `
                    -Prompt "Return to Award Menu?`nType Y or N and press [Enter]"
            }
            until ($returnmenu -in ('Y','N'))
        }
        #-------------------------------------------
        # End of Season Trophies
        "3" {
            $trophies = @{}
            clear-host
            do {
                $trophyinput = Read-Host `
                    -Prompt "Which trophy to report on?`n[1] 25m Improvement`n[2] Distance`n[3] IM`n[4] Pinetathlon`n[5] Endurance`n[6] Aggregate Points`n[7] Club Champion`n[8] All Trophies`nEnter 1 to 8 and press [Enter]"
            }
            until ($trophyinput -in (1..8))
            if ($trophyinput -in (1,8)) {
                foreach ($stroke in $strokearray) {
                    $trophies["25 Improvement - $($stroke)"] = Get-25ImprovementTrophies $cleandata -Strokename $stroke -Verbose
                }
            }
            if ($trophyinput -in (2,8)) {  
                $trophies["Distance"] = Get-DistanceTrophies $cleandata -Verbose
            }
            if ($trophyinput -in (3,8)) {  
                $trophies["IM"] = Get-IMPointsTrophies $cleandata -Verbose
            }
            if ($trophyinput -in (4,8)) {  
                $trophies["Pinetathlon"] = Get-PinetathlonTrophies $cleandata -Verbose
            }
            if ($trophyinput -in (5,8)) {  
                $trophies["Endurance"] = Get-EnduranceTrophies $cleandata -Verbose
            }
            if ($trophyinput -in (6,8)) {  
                $trophies["Aggregate Points"] = Get-AggregatePointsTrophies $cleandata -Verbose
            }
            if ($trophyinput -in (7,8)) {
                $trophies["Club Champion"] = Get-ClubChampion $cleandata -Verbose
            }
            if (-not(Test-Path "$($ResultsPath)\Trophies")) {
                New-Item -Name "Trophies" -ItemType Directory -Path $ResultsPath
            }
            foreach ($Trophy in $trophies.Keys) {
                $trophies.$Trophy | export-csv "$($ResultsPath)\Trophies\$($Trophy).csv" -NoTypeInformation
            }
            #clear-host
            Write-Host "Trophy reports were written to $($ResultsPath)\Trophies"
            do {
                $returnmenu = Read-Host `
                    -Prompt "Return to Award Menu?`nType Y or N and press [Enter]"
            }
            until ($returnmenu -in ('Y','N'))
        }
        #-------------------------------------------
    }
}
until ($returnmenu -eq 'N')
