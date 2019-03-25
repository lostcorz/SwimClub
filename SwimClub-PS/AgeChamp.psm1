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
                    foreach ($i in (0..($sorted.count-1))) {
                        if ($i -eq 0) {
                            $sorted[$i].Points = $1st
                        }
                        elseif ($i -eq 1) {
                            $sorted[$i].Points = $2nd
                        }
                        elseif ($i -eq 2) {
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
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData
    )
    begin {
        $outputarray = @()
    }
    process {
        $swimmers = $data.values.values.Swimmer | select -unique
        $events = $data.Keys
        foreach ($swimmer in $swimmers) {
            $obj = New-Object psobject
            $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swimmer
            $obj | Add-Member -MemberType NoteProperty -Name Category -Value $null
            $obj | Add-Member -MemberType NoteProperty -Name TotalPoints -Value $null
            foreach ($evt in $events) {
                $obj | Add-Member -MemberType NoteProperty -Name $evt -Value $null
            }
            $outputarray += $obj
        }
        foreach ($evt in $SwimmerData.Keys) {
            foreach ($cat in $SwimmerData[$evt].Keys) {
                foreach ($swimmer in $SwimmerData[$evt][$cat]) {
                    $arrayobj = $outputarray | where {$_.Swimmer -eq $swimmer.Swimmer}
                    $arrayobj.Category = $cat
                    $arrayobj.$evt = $swimmer.Points
                }
            }
        }
        foreach ($swimmer in $outputarray) {
            $totalpoints = 0
            foreach ($evt in $events) {
                $totalpoints += $swimmer.$evt
            }
            $swimmer.TotalPoints = $totalpoints
        }   
    }
    end {
        Write-Output ($outputarray | sort Category, TotalPoints -Descending)
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
Export-ModuleMember -function Get-AgeChampions