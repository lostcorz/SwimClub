function Get-SwimmerData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$csvPath
    )
    begin {
        $files=Get-ChildItem $csvPath -File -filter "clubchamps*.csv"
        $swimmers=@{}
    }
    process {
        foreach ($file in $files) {
            $meetDate=($file.name).Substring(($file.name).indexof("_")+1,6)
            if ($file.name -like "clubchamps*") {
                $csv = Import-Csv $file.FullName -Header (1..185)
                $SwimmerCol = 125
                $AgeCol = 126
                $SeedCol = 128
                $TimeCol = 131
                $PointsCol = 134
                $EventCol = 8
                $DistIndex = (0-1) #Event Distance relative to 'SC' in string
                $StrokeIndex = (0+2) #Event name relative to 'SC' in string
                $Genderindex = 3 #Gender in Event string
                $filetype = "Meet"
            }
            else {
                $csv = import-csv $file.FullName
                $eventname=(($file.name).Substring(0,($file.name).indexof("_"))).trim()
            }
            foreach ($line in $csv) {
                if ($filetype -eq "Meet") {
                    $rawEventName = ($line.$Eventcol).Replace('"', '').split(' ')
                    $scIndex = $rawEventName.indexof("SC")
                    $eventname = "$($rawEventName[($scIndex + $StrokeIndex)])$($rawEventName[($scIndex + $DistIndex)])"
                    $properSwimmerName = ($line.$SwimmerCol).Replace('"', '')
                    $Age = ($line.$AgeCol).Replace('"',"").Trim()
                    $Seed = ($line.$SeedCol).Replace('"', '')
                    $Time = ($line.$TimeCol).Replace('"', '')
                    if ($rawEventName[$Genderindex] -eq "Girls") {
                        $gender = 'Girls'
                    }
                    else {
                        $gender = 'Boys'
                    }
                    $cat = "$($age)$($gender)"
                    $rawpoints = ($line.$PointsCol).Replace('"', '')
                    if ($rawpoints -ge 1) {
                        $points = [int]$rawpoints
                    }
                    else {
                        $points = $null
                    }
                }
                else {
                    $properSwimmerName = ($line.name -replace '[^a-zA-Z ,-]','').Trim()
                    $Age=[int]($line.age -replace '[^0-9]','')
                    $time = $line.time
                    $seed = $line.seedtime
                    if ($line.points) {
                        $points = $line.points
                    }
                    else {
                        $points = $null
                    }
                }
                if ($properSwimmerName -notmatch ",") {
                    $splitname = $properSwimmerName.split(" ")
                    $properSwimmerName = "$($splitname[1]), $($splitname[0])"
                }
                if (-not $swimmers.$eventname) {
                    $swimmers.$eventname = @{}
                }
                if (-not $swimmers.$eventname.$cat) {
                    $swimmers.$eventname.$cat = @()
                }
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $properSwimmerName
                $obj | Add-Member -MemberType NoteProperty -Name Age -Value $Age
                $obj | Add-Member -MemberType NoteProperty -Name Gender -Value $Gender
                $obj | Add-Member -MemberType NoteProperty -Name Time -Value $time
                $obj | Add-Member -MemberType NoteProperty -Name Timespan -Value ([timespan]::ParseExact($time, $timepatterns, [cultureinfo]::CurrentCulture))
                $obj | Add-Member -MemberType NoteProperty -Name Points -Value $points
                $swimmers[$eventname][$cat] += $obj
            }
        }
    }
    end {
        Write-Output $swimmers
    }
}
function Confirm-SwimmerData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]$SwimmerData
    )
    begin {
        $1st = 5
        $2nd = 3
        $3rd = 1
    }
    process {
        foreach ($evt in $SwimmerData.Keys) {
            foreach ($cat in $SwimmerData[$evt].Keys) {
                $sorted = $SwimmerData[$evt][$cat] | sort timespan
                if ($sorted.count -gt 1) {
                    $count = 
                    foreach ($i in (0..($sorted.count-1))) {
                        if ($i = 0) {
                            $sorted[$i].Points = $1st
                        }
                        elseif ($i = 1) {
                            $sorted[$i].Points = $2nd
                        }
                        elseif ($i = 2) {
                            $sorted[$i].Points = $3rd
                        }
                        else {
                            $sorted[$i].Points = 0
                        }
                    }
                }
                else {
                    $sorted.Points = $1st
                }
            }
        }
    }
    end {
        Write-Output $SwimmerData
    }
}
function Get-AgeChampions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData,
        [Parameter(HelpMessage="Path to AwardsList.csv file")]$AwardsListLocation
    )
    begin {
        $pbnum = $PRCACAwardsConfig['Achievement']['PBsPerAward']
        $pathcheck = Test-Path "$AwardsListLocation\AwardsList.csv" -ErrorAction SilentlyContinue
        if ($pathcheck) {
            $AwardsList = Import-csv $AwardsListLocation\"AwardsList.csv"    
        }
        else {
            $AwardsList = $null
        }
        $array = @()
    }
    process {
        foreach ($swimmer in $SwimmerData.Keys) {
            $pbtable = @{}
            $AwardsDue = @()
            foreach ($stroke in $SwimmerData[$swimmer].Keys) {
                if ($SwimmerData[$swimmer][$stroke].pb -contains "Yes") {
                    $pbs = ($SwimmerData[$swimmer][$stroke] | where {$_.pb -eq "Yes"}).count
                    if (-not $pbs) {
                        $pbs = 1                    
                    }
                    $pbtable[$stroke] = $pbs
                }
            }
            foreach ($stroke in $pbtable.Keys){
                #---------------------------------
                # Achievement award criteria logic
                #---------------------------------
                # set the pb number
                $totalpbs = $pbtable[$stroke]
                #-----------------------------------------
                # 25m efforts carry over to 50m with no previous combined award.
                if ($stroke -like "*50" -and ($pbtable["$($stroke.Replace("50","25"))"] % $pbnum) -in (1..($pbnum-1))) {
                    $totalpbs = ($pbtable["$($stroke.Replace("50","25"))"] % $pbnum) + $pbtable[$stroke]
                    $25slash50 = $true
                }
                else {
                    $25slash50 = $false
                }
                #Only continue to process if there are 3 or more pbs
                If ($totalpbs -ge $pbnum) {
                    Write-Verbose "Award triggered - $totalpbs pbs in $Stroke for $swimmer"
                    #-----------------------------------------
                    # 3 PBs in one event.
                    if ($totalpbs -ge $pbnum -and $25slash50) {
                        $AwardsDue += "$($stroke.Replace("50","25"))/50"
                    }
                    elseif ($totalpbs -ge $pbnum) {
                        $AwardsDue += $stroke
                    }
                    #-----------------------------------------
                    # 6 PBs in one event.
                    if ($totalpbs -ge ($pbnum * 2) -and $25slash50) {
                        $AwardsDue += $stroke
                    }
                    elseif ($totalpbs -ge ($pbnum * 2)) {
                        $AwardsDue += "$stroke(#2)"
                    }
                    #-----------------------------------------
                    # 9 PBs in one event.
                    if ($totalpbs -ge ($pbnum * 3) -and $25slash50) {
                        $AwardsDue += "$stroke(#2)"
                    }
                    elseif ($totalpbs -ge ($pbnum * 3)) {
                        $AwardsDue += "$stroke(#3)"
                    }
                }
                else {
                    Write-Verbose "Insufficient pbs in $Stroke for $swimmer - $totalpbs"
                }
            }
            if ($AwardsDue.count -gt 0) {
                $newawards = $null
                $swmrawards = ($AwardsList | where {$_.swimmer -like $swimmer}).achievementawards
                foreach ($award in $AwardsDue) {
                    if ($swmrawards -notlike "*$($award)*" -and $newawards -eq $null) {
                        $newawards += $award
                    }
                    elseif ($swmrawards -notlike "*$($award)*" -and $newawards -ne $null) {
                        $newawards += ", $award"
                    }
                }
                if ($newawards) {
                    $obj = New-Object PSObject
                    $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swimmer
                    $obj | Add-Member -MemberType NoteProperty -Name AwardsDue -Value $newawards
                    $array += $obj
                    Write-Verbose "Awards in $newawards for $swimmer"
                }
            }
        }
    }
    end {
        Write-Output ($array | sort Swimmmer)
    }
}

[String[]]$timepatterns = @(
            'ss'
            'ss\.ff'
            'ss\.f'
            'm\:ss\.ff'
            'm\:ss\.f'
            'mm\:ss\.ff'
            'mm\:ss\.f'
        )

Export-ModuleMember -function Get-SwimmerData
Export-ModuleMember -function Confirm-SwimmerData
Export-ModuleMember -function Get-AchievementAwards
Export-ModuleMember -function Get-TowelAwards
Export-ModuleMember -function Update-AwardsList
Export-ModuleMember -function Get-AggregatePointsTrophies
Export-ModuleMember -function Get-25ImprovementTrophies
Export-ModuleMember -function Get-IMPointsTrophies
Export-ModuleMember -Function Get-PinetathlonTrophies
Export-ModuleMember -function Get-DistanceTrophies
Export-ModuleMember -function Get-EnduranceTrophies
Export-ModuleMember -function Get-ClubChampion
Export-ModuleMember -function Get-ModifiedData
Export-ModuleMember -function Get-SwimmersEvents
Export-ModuleMember -function Get-ExcelData