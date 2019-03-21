param (
    [Parameter()]$SwimClubPath = "D:\Home\Shaun\OneDrive\Documents\SwimClub",
    [Parameter(Mandatory=$true)]$Season
)
Import-Module "$SwimClubPath\Powershell\Swim.Club.psm1" -Force
$data = get-swimmerdata "$SwimClubPath\Data\$Season" -verbose | Confirm-SwimmerData -verbose
$trophies = @{}
$trophies['1. 25 Improvement - Butterfly'] = Get-25ImprovementTrophies $data -Strokename 'Butterfly' -Verbose
$trophies['1. 25 Improvement - Backstroke'] = Get-25ImprovementTrophies $data -Strokename 'Backstroke' -Verbose
$trophies['1. 25 Improvement - Breaststroke'] = Get-25ImprovementTrophies $data -Strokename 'Breaststroke' -Verbose
$trophies['1. 25 Improvement - Freestyle'] = Get-25ImprovementTrophies $data -Strokename 'Freestyle' -Verbose
$trophies['2. Distance'] = Get-DistanceTrophies $data -Verbose
$trophies['3. IM'] = Get-IMPointsTrophies $data -Verbose
$trophies['4. Pinetathlon'] = Get-PinetathlonTrophies $data -Verbose
$trophies['5. Endurance'] = Get-EnduranceTrophies $data -Verbose
$trophies['6. Aggregate Points'] = Get-AggregatePointsTrophies $data -Verbose
$trophies['7. Club Champion'] = Get-ClubChampion $data -Verbose
$array = @()
foreach ($Trophy in $trophies.Keys) {
    $trophies.$Trophy | export-csv "$SwimClubPath\ClubAwards\$season\Trophies\$($Trophy.Substring(3,($trophy.length - 3))).csv" -NoTypeInformation
    if ($Trophy -like "*. [IPD]*") {
        foreach ($cat in ($trophies[$trophy].Category | select -Unique)) {
            $swimmer = $trophies[$trophy] | where {$_.Category -eq $cat -and $_.CategoryPlacing -eq 1}
            if ($swimmer.Count -ge 2) {
                $recip = $null
                foreach ($i in $swimmer) {
                    if ($swimmer.IndexOf($i) -lt ($swimmer.count - 1)) {
                        $recip += "$($i.swimmer) & "
                    }
                    else {
                        $recip += "$($i.swimmer)"
                    }
                } 
            }
            else {
                $recip = $swimmer.Swimmer
            }
            $array += New-Object psobject -Property @{
                TrophyOrder = $trophy.Substring(0,1)
                SubOrder = $null
                Str = "$trophy - $($cat): $recip"
            } 
        }
    }
    elseif ($Trophy -like "*. [2EC]*") {
        $swimmer = $trophies[$trophy] | select -First 1
        $recips = $trophies[$trophy] | where {$_.TotalPoints -eq $swimmer.totalpoints}
        if ($Trophy -notlike "*. 2*" -and $recips.count -ge 2) {
            $recip = $null
            foreach ($i in $recips) {
                if ($recips.IndexOf($i) -lt ($recips.count - 1)) {
                    $recip += "$($i.swimmer) & "
                }
                else {
                    $recip += "$($i.swimmer)"
                }
            } 
        }
        else {
            $recip = $swimmer.Swimmer
        }
        $array += New-Object psobject -Property @{
            TrophyOrder = $trophy.Substring(0,1)
            SubOrder = $null
            Str = "$($trophy): $recip"
        } 
    }
    elseif ($Trophy -like "*. Agg*") {
        foreach ($cat in ($trophies[$trophy].Category | select -Unique)) {
            $catswimmers = $trophies[$trophy] | where {$_.Category -eq $cat -and $_.CategoryPlacing -match '\['}
            foreach ($swimmer in $catswimmers) {
                $placing = ($swimmer.CategoryPlacing) -replace '[\[\]]',''
                $array += New-Object psobject -Property @{
                    TrophyOrder = $trophy.Substring(0,1)
                    SubOrder = $placing
                    Str = "$trophy - $($cat): $placing, $($swimmer.points) points, $($swimmer.Swimmer)"
                } 
            }
        }
    }
}
$finallist = @()
$groups = $array | group -Property TrophyOrder | sort Name
foreach ($grp in $groups) {
    if ($grp.group.SubOrder -contains 1) {
        $subgroups = $grp.group | Group-Object -Property {$_.Str.Substring(($_.str.Indexof('-')+2),(($_.str.Indexof(':')-2)-$_.str.Indexof('-')))}
        foreach ($sub in $subgroups) {
            $finallist += ($sub.Group | sort Suborder -Descending).str
            if ($subgroups.IndexOf($sub) -lt ($subgroups.Count -1)) {
                $finallist += "          ------------------------------------------------"
            }
        }
    }
    else {
        $finallist += ($grp.Group | sort str).str
    }
    if ($groups.IndexOf($grp) -lt ($groups.Count -1)) {
        $finallist += "--------------------------------------------------------------------"
    }
}
$finallist | Out-File "$SwimClubPath\ClubAwards\$season\Trophies\Trophies.txt"
Invoke-Item "$SwimClubPath\ClubAwards\$season\Trophies\Trophies.txt"