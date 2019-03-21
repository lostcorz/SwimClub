param (
    [Parameter()]$SwimClubPath = "D:\Home\Shaun\OneDrive\Documents\SwimClub",
    [Parameter()]$Season = "18.19",
    [Switch]$ImportAwardsList
)
Import-Module "$SwimClubPath\Powershell\Swim.Club.psm1" -Force
$cleandata = get-swimmerdata "$SwimClubPath\Data\$Season" -Verbose | Confirm-SwimmerData -Verbose
$clubnightdate = ($cleandata.Values.Values.Date | measure -max).Maximum
switch ($ImportAwardsList) {
    $true {
        $newawards = Get-AchievementAwards $cleandata -AwardsListLocation "$SwimClubPath\ClubAwards\$season"
        $updatedawards = Update-AwardsList -NewAwardData $newawards -AwardsListLocation "$SwimClubPath\ClubAwards\$season"
    }
    Default {
        $newawards = Get-AchievementAwards $cleandata
        $updatedawards = Update-AwardsList -NewAwardData $newawards
    }
}
$newawards | Out-File "$SwimClubPath\ClubAwards\$season\AchievementAwards\Awards_$clubnightdate.txt"
if (Test-Path "$SwimClubPath\ClubAwards\$season\AwardsList.csv") {
    $date = Get-Date -Format "yyMMdd"
    Copy-Item "$SwimClubPath\ClubAwards\$season\AwardsList.csv" -Destination "$SwimClubPath\ClubAwards\$season\_HistoricAwardslists\AwardsList_$date.csv"
}
$updatedawards | Export-Csv -NoTypeInformation "$SwimClubPath\ClubAwards\$season\AwardsList.csv" -force
Invoke-Item "$SwimClubPath\ClubAwards\$season\AchievementAwards\Awards_$clubnightdate.txt"