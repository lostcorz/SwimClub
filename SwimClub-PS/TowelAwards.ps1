param (
    [Parameter()]$SwimClubPath = "D:\Home\Shaun\OneDrive\Documents\SwimClub",
    [Parameter()]$Season = "18.19",
    [Parameter()]$Weeks = 4,
    [Parameter(Mandatory=$true,HelpMessage="First Club Night date in dd/mm/yy format")]$StartDate,
    [Parameter(Mandatory=$true)][ValidateSet('Backstroke','Breaststroke','Butterfly','Freestyle')]$Strokename
)
Import-Module "$SwimClubPath\Powershell\Swim.Club.psm1" -Force
$swimdata = get-swimmerdata "$SwimClubPath\Data\$Season" -Verbose | Confirm-SwimmerData -Verbose
$newawards = Get-TowelAwards $swimdata -Stroke $Strokename -FirstClubNight $StartDate -AwardsListLocation "$SwimClubPath\ClubAwards\$season" -numberofweeks $Weeks
if ($newawards) {
    $newawards | Out-File "$SwimClubPath\ClubAwards\$Season\TowelAwards\$strokename.txt"
    if (Test-Path "$SwimClubPath\ClubAwards\$season\AwardsList.csv") {
        $date = Get-Date -Format "yyMMdd"
        Copy-Item "$SwimClubPath\ClubAwards\$season\AwardsList.csv" -Destination "$SwimClubPath\ClubAwards\$season\_HistoricAwardslists\AwardsList_$date.csv"
    }
    $updatedawards = Update-AwardsList -NewAwardData $newawards -AwardsListLocation "$SwimClubPath\ClubAwards\$season"
    $updatedawards | Export-Csv -NoTypeInformation "$SwimClubPath\ClubAwards\$season\AwardsList.csv" -force
    Invoke-Item "$SwimClubPath\ClubAwards\$Season\TowelAwards\$strokename.txt"
}