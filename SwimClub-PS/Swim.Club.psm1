$PRCACAwardsConfig = @{
    "Points" = @{
        "Regular" = @{
            #All Below are 1 Point
            "2points" = "02.49"
            "3points" = "01.49"
            "4points" = "00.49"
            "5points" = "01.49"
            "6points" = "02.49"
            "7points" = "04.99"
            #All above are 8 Points
        }
        "Endurance" = @{
            #All Below are 1 Point
            "3points" = "14.99"
            "4points" = "09.99"
            "5points" = "04.99"
            "6points" = "09.99"
            "7points" = "14.99"
            #All above are 8 Points
        }
    }
    "Achievement" = @{
        "PBsPerAward" = 3
    }
    "Towel" = @{
        "AgeRanges" = @{
            "7andUnder" = (4..7)
            "8and9" = (8, 9)
            "10and11" = (10, 11)
            "12andOver" = (12..17)
        }
        "Distances" = "25", "50", "100"
        "MinPoints" = 16
    }
    "AggregatePoints" = @{
        "Events" = @{
            "Backstroke" = "25", "50", "100"
            "Breaststroke" = "25", "50", "100"
            "Butterfly" = "25", "50", "100"
            "Freestyle" = "25", "50", "100", "200", "400"
        }
        "AgeRanges" = @{
            "7andUnder" = (4..7)
            "8and9" = (8, 9)
            "10and11" = (10, 11)
            "12andOver" = (12..17)
        }
        "TopPercentAwarded" = 25
    }
    "25Improvement" = @{
        "ProgressTimes" = @{
            "Backstroke" = "28.00"
            "Breaststroke" = "29.00"
            "Butterfly" = "25.00"
            "Freestyle" = "25.00"
        }
    }
    "IM" = @{
        "Distances" = "100", "200"
        "AgeRanges" = @{
            "9andUnder" = (4..9)
            "10and11" = (10, 11)
            "12andOver" = (12..17)
        }
    }
    "Pinetathlon" = @{
        "AgeRanges" = @{
            "9andUnder" = (4..9)
            "10and11" = (10, 11)
            "12andOver" = (12..17)
        }
        "Events" = @{
            "9andUnder" = "Freestyle100", "Freestyle200", "Backstroke100", "Breaststroke100", "IM100", "Butterfly50"
            "10and11" = "Freestyle100", "Freestyle200", "Backstroke100", "Breaststroke100", "IM100", "Butterfly50"
            "12andOver" = "Freestyle100", "Freestyle200", "Backstroke100", "Breaststroke100", "IM200", "Butterfly100"
        }
    }
    "Distance" = @{
        "AgeRanges" = @{
            "Junior" = (4..11)
            "Senior" = (12..17)
        }
        "Events" = @{
            "Junior" = "Freestyle200"
            "Senior" = "Freestyle200", "Freestyle400"
        }
    }
    "Endurance" = @{
        "MinAge" = 11
        "TopXEvents" = 4
        "Events" = "IM400", "Freestyle800", "Backstroke200", "Breaststroke200", "Butterfly200"
    }
    "ClubChampion" = @{
        "MinAge" = 10
        "TopXEvents" = 13
    }
}
function Get-SwimmerData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$csvPath
    )
    begin {
        $files=Get-ChildItem $csvPath -File -filter "*.csv"
        $swimmers=@{}
    }
    process {
        foreach ($file in $files) {
            $meetDate=($file.name).Substring(($file.name).indexof("_")+1,6)
            if ($file.name -like "ClubNight_*") {
                $csv = Import-Csv $file.FullName -Header (1..185)
                $SwimmerCol = 20
                $AgeCol = 21
                $SeedCol = 23
                $TimeCol = 26
                $PointsCol = 29
                $EventCol = 8
                $DistIndex = (0-1) #Event Distance relative to 'SC' in string
                $StrokeIndex = (0+2) #Event name relative to 'SC' in string
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
                if (-not $swimmers.$properSwimmerName) {
                    write-verbose "Adding Swimmer $properSwimmerName"
                    $swimmers.$properSwimmerName = @{}
                }
                if (-not $swimmers.$properSwimmerName.$eventname) {
                    write-verbose "Adding Event $eventname for Swimmer $properSwimmerName"
                    $swimmers.$properSwimmerName.$eventname = @()
                }
                Write-Verbose "Adding $eventname data on $meetdate for Swimmer $properSwimmerName"
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Date -Value $meetDate
                $obj | Add-Member -MemberType NoteProperty -Name Age -Value $Age
                $obj | Add-Member -MemberType NoteProperty -Name pb -Value $null
                $obj | Add-Member -MemberType NoteProperty -Name Time -Value $time
                $obj | Add-Member -MemberType NoteProperty -Name seedTime -Value $seed
                $obj | Add-Member -MemberType NoteProperty -Name Points -Value $points
                $obj | Add-Member -MemberType NoteProperty -Name Changed -Value $null
                $swimmers[$properSwimmerName][$eventname] += $obj
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
        #endurance distances
        $enduranceDist = $PRCACAwardsConfig['Endurance']['Events']
        #Points Definition
        $ptsdefs= $PRCACAwardsConfig['Points']
        #Map Points Definitions to TimeSpan value in Hash table
        $timespans = @{}
        foreach ($type in $ptsdefs.Keys) {
            $timespans[$type] = @{}
            foreach ($def in $ptsdefs[$type].keys) {
                $key = "$($def[0])ptTimeSpan" 
                $value = [timespan]::ParseExact($ptsdefs[$type][$def], $timepatterns, [cultureinfo]::CurrentCulture)
                $timespans.$type.$key = $value
            }
        }
    }
    process {
        foreach ($swimmer in $SwimmerData.Keys) {
            foreach ($stroke in $SwimmerData[$swimmer].Keys) {
                if ($stroke -in $enduranceDist) {
                    $endurance = $true
                    $pnts = $timespans['endurance']
                }
                else {
                    $endurance = $false
                    $pnts = $timespans['regular']
                }
                #Order the data by meet date and get the count of meets
                $ordered = $SwimmerData[$swimmer][$stroke] | Sort-Object date
                $orderedCount = $ordered.count
                if (-not $orderedCount -and $ordered.Date) {
                    $orderedCount = 1
                }
                $seedtime = $null
                foreach ($i in (0..($orderedCount-1))) {
                    $change = $null
                    $points = $null
                    #Set Meet Time Span, bug out if it is not a time (eg 'DQ')
                    try {
                        $meettimespan = [timespan]::ParseExact($ordered[$i].Time, $timepatterns, [cultureinfo]::CurrentCulture)
                    }
                    catch {
                        Continue
                    }
                    #Set the seed time span, if there is one, for the first event of the season
                    if (-not $seedtime -and $ordered[$i].seedTime -ne "NT") {
                        $seedtime = $ordered[$i].seedTime
                        $SeedTimeSpan = [timespan]::ParseExact($seedTime, $timepatterns, [cultureinfo]::CurrentCulture)
                    }
                    #Else, if the carried seed is not the same as the current seed - change it
                    elseif ($seedtime -and $ordered[$i].seedTime -ne $seedtime) {
                        $ordered[$i].seedTime = $seedtime
                        $change = "SeedTime"
                    }
                    #----------------------------------------------------------------------------------------------------
                    #                 MAIN POINTS LOGIC
                    #----------------------------------------------------------------------------------------------------
                    #if 1st event of the season and there's no seed.
                    if (-not $seedtime -and $ordered[$i].seedTime -eq "NT") {
                        $seedtime = $ordered[$i].time
                        $SeedTimeSpan = [timespan]::ParseExact($seedTime, $timepatterns, [cultureinfo]::CurrentCulture)
                        $ordered[$i].pb = "No"
                        if ($endurance) {
                            $points = 4
                        } 
                        else {
                            $points = $null
                        }
                    }
                    #Else, if meettimespan is slower than seedtimespan
                    elseif ($meetTimeSpan -gt $SeedTimeSpan) {
                        $timediff = $meetTimeSpan - $SeedTimeSpan
                        if ($endurance -and $timediff -le $pnts.'5ptTimeSpan') {
                            $points = 5
                        }
                        elseif ($timediff -le $pnts.'4ptTimeSpan') {
                            $points = 4
                        }
                        elseif ($timediff -le $pnts.'3ptTimeSpan') {
                            $points = 3
                        }
                        #no 2 point range for endurance
                        elseif (-not $endurance -and $timediff -le $pnts.'2ptTimeSpan') {
                            $points = 2
                        }
                        #all other standard results are 1 point
                        else {
                            $points = 1
                        }
                        #set pb to no
                        $ordered[$i].pb = "No"
                    }
                    #Else, if meettimespan is faster than seedtimespan
                    elseif ($meetTimeSpan -lt $SeedTimeSpan) {
                        $timediff = $SeedTimeSpan - $meetTimeSpan
                        if (-not $endurance -and $timediff -le $pnts.'4ptTimeSpan') {
                            $points = 4
                        }
                        elseif ($timediff -le $pnts.'5ptTimeSpan') {
                            $points = 5
                        }
                        elseif ($timediff -le $pnts.'6ptTimeSpan') {
                            $points = 6
                        }
                        elseif ($timediff -le $pnts.'7ptTimeSpan') {
                            $points = 7
                        }
                        #all other standard results are 8 points
                        else {
                            $points = 8
                        }
                        #set pb to yes and seedtime to the new time
                        $ordered[$i].pb = "Yes"
                        $seedtime = $ordered[$i].Time
                        $SeedTimeSpan = [timespan]::ParseExact($seedTime, $timepatterns, [cultureinfo]::CurrentCulture)
                    }
                    #else 
                    else {
                        $ordered[$i].pb = "No"
                        $points = 4
                    }
                    #----------------------------------------------------------------------------------------------------
                    #Add any points changes to what's changed.
                    if ($points -eq $null -and -not $change) {
                        $change = $null
                    }
                    elseif ($ordered[$i].Points -ne $points -and -not $change) {
                        $change = "Points"
                    }
                    elseif ($ordered[$i].Points -ne $points -and $change) {
                        $change += ", Points"
                    }
                    if ($change) {
                        Write-Verbose "$Change changes for $stroke at meet $($ordered[$i].date) for $swimmer"
                    }
                    else {
                        Write-Verbose "No changes for $stroke at meet $($ordered[$i].date) for $swimmer"
                    }
                    #set the correct points and changes
                    $ordered[$i].Points = $points
                    $ordered[$i].Changed = $change
                }
            }
        }
    }
    end {
        Write-Output $SwimmerData
    }
}
function Get-AchievementAwards {
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
                    $pbs = ($SwimmerData[$swimmer][$stroke] | Where-Object {$_.pb -eq "Yes"}).count
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
                $swmrawards = ($AwardsList | Where-Object {$_.swimmer -like $swimmer}).achievementawards
                foreach ($award in $AwardsDue) {
                    if ($swmrawards -notlike "*$($award)*" -and $newawards -eq $null) {
                        $newawards += $award
                    }
                    elseif ($swmrawards -notlike "*$($award)*" -and $newawards -ne $null) {
                        $newawards += ", $award"
                    }
                    else {
                        Write-Verbose "$swimmer has already earnt award for $award"
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
        Write-Output ($array | Sort-Object Swimmmer)
    }
}
function Get-TowelAwards {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData,
        [Parameter(Mandatory=$true)][ValidateSet('Butterfly','Backstroke','Breaststroke','Freestyle')]$Strokename,
        [Parameter(HelpMessage="Path to AwardsList.csv file")]$AwardsListLocation,
        [Parameter(Mandatory=$true,HelpMessage="Date in dd/mm/yy format")]$FirstClubNight,
        [Parameter()]$numberofweeks=4
    )
    begin {
        $towel = $PRCACAwardsConfig['Towel']
        #Create the date filters based on the first club night entered & number of weeks
        $1stClubNightDate = Get-Date $FirstClubNight
        $pathcheck = Test-Path "$AwardsListLocation\AwardsList.csv" -ErrorAction SilentlyContinue
        if ($pathcheck) {
            $AwardsList = Import-csv $AwardsListLocation\"AwardsList.csv"    
        }
        else {
            $AwardsList = $null
        }
        $filters = @()
        $count = 0
        while ($filters.count -lt $numberofweeks) {
            $newclubnightdate = $1stClubNightDate.AddDays($count)
            $filter = $newclubnightdate.ToString("yyMMdd")
            $count += 7
            $filters += $filter
        }
        #Create the event filter
        $events = @()
        foreach ($distance in $towel['distances']) {
            $events += "$Strokename$distance"
        }
        $pointsarray = @()
        $array = @()
    }
    process {
        foreach ($swmr in $SwimmerData.Keys) {
            $swmrawards = ($awardslist | Where-Object {$_.swimmer -eq $swmr}).TowelAwards
            if (-not $swmrawards) {
                $points = $null
                $swmrevents = $SwimmerData[$swmr].Keys | Where-Object {$_ -in $events}
                $swmrage = ($SwimmerData[$swmr].Values.age | Measure-Object -Maximum).Maximum
                foreach ($stroke in $swmrevents) {
                    $StrokeEvents = $SwimmerData[$swmr][$stroke] | Where-Object {$_.Date -in $filters}
                    $StrokePoints = ($StrokeEvents | Measure-Object -Property Points -sum).Sum
                    $points += $StrokePoints
                }
                if ($points -ge $Towel['minpoints']) {
                    $obj = New-Object PSObject
                    $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr
                    $obj | Add-Member -MemberType NoteProperty -Name Age -Value $swmrage
                    $obj | Add-Member -MemberType NoteProperty -Name Points -Value $points
                    $pointsarray += $obj
                    Write-Verbose "$swmr qualifies for towel award consideration - $points points"
                }
                else {
                    Write-Verbose "$swmr does not qualify for towel award consideration - $points points"
                }
            }
            else {
                Write-Verbose "$swmr has already received a towel award - skipping"
            }
        }
        foreach ($range in $towel['AgeRanges'].Keys) {
            $agetowel = $null
            $rangeswimmers = @()
            $rangeswimmers += $pointsarray | Where-Object {$_.Age -in $towel['AgeRanges'][$range]} | Sort-Object Points -Descending
            if ($rangeswimmers) {
                $toppoints = $rangeswimmers[0].points
                $count = ($rangeswimmers | Where-Object {$_.Points -eq $toppoints}).count
                if (-not $count) {
                    $count = 1
                }
                While ($count -ge 1) {
                    $agetowel = New-Object psobject -Property @{
                        'AgeGroup' = $range
                        'Swimmer' = $rangeswimmers[$count-1].swimmer
                        'Points' = $rangeswimmers[$count-1].points
                        'AwardStroke' = $Strokename
                    }
                    $array += $agetowel
                    $count -= 1
                }
            }
        }
    }
    end {
        Write-Output $array
    }
}
function Get-AggregatePointsTrophies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData
    )
    begin {
        $Aggpoints = $PRCACAwardsConfig['AggregatePoints']
        $array = @()
        #create filters object from eventfilter table
        $filters = @()
        foreach ($evt in $Aggpoints['Events'].keys) {
            foreach ($distance in $Aggpoints['Events'][$evt]) {
                $filters += "$evt$distance"
            }
        }
    }
    process {
        foreach ($swmr in $SwimmerData.Keys) {
            write-verbose "Aggregating points for $swmr"
            $swmrage = ($SwimmerData[$swmr].values.age | Measure-Object -Maximum).Maximum
            $events = $SwimmerData[$swmr].Keys | Where-Object {$_ -in $filters}
            $swmrpoints = 0
            foreach ($evt in $events) {
                $swmrpoints += ($SwimmerData[$swmr][$evt].points | Measure-Object -Sum).Sum
            }
            $rangename = ($Aggpoints['AgeRanges'].GetEnumerator() | Where-Object {$_.Value -contains $swmrage}).name
            $obj = New-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr
            $obj | Add-Member -MemberType NoteProperty -Name Category -Value $rangename
            $obj | Add-Member -MemberType NoteProperty -Name Age -Value $swmrage
            $obj | Add-Member -MemberType NoteProperty -Name Points -Value $swmrpoints
            $obj | Add-Member -MemberType NoteProperty -Name CategoryPlacing -Value $null
            $array += $obj
        }
        foreach ($range in $Aggpoints['AgeRanges'].Keys) {
            Write-Verbose "Ranking $range range swimmers"
            $placing = 1
            $trophyplaces = [math]::Round((($array | Where-Object {$_.Category -eq $range}).count) * ($Aggpoints['TopPercentAwarded']/100))
            $groups = $array | Where-Object {$_.Category -eq $range} | Group-Object -Property Points -AsHashTable
            foreach ($grp in ($groups.Keys | Sort-Object -desc)) {
                $grpcount = $groups[$grp].Count
                foreach ($swmr in $groups[$grp]) {
                    if ($placing -in (1..$trophyplaces)){
                        $place = "[$($placing)]"
                    }
                    else {
                        $place = $placing
                    }
                    $swmr.categoryplacing = $place
                }
                $placing += $grpcount
            }
        }
    }
    end {
        write-output ($array | Sort-Object Cat*)
    }
}
function Get-25ImprovementTrophies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData,
        [Parameter()][ValidateSet('Butterfly','Backstroke','Breaststroke','Freestyle')]$Strokename
    )
    begin {
        $25Improvement = $PRCACAwardsConfig['25Improvement']
        $50Cutofftime = [timespan]::ParseExact($25Improvement['ProgressTimes'][$strokename], $timepatterns, [cultureinfo]::CurrentCulture)
        $array = @()
    }
    process {
        $meets = $SwimmerData.Values.values.Date | Select-Object -Unique | Sort-Object
        foreach ($swmr in $SwimmerData.Keys) {
            if ($SwimmerData[$swmr].Keys | Where-Object {$_ -like "$($strokename)25"}) {
                Write-Verbose "Fetching 25m $strokename times for $swmr"
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr
                $Fastest25Span = $null
                $First25Span = $null
                foreach ($meet in $meets) {
                    $25meet = $SwimmerData[$swmr]["$($strokename)25"] | Where-Object {$_.Date -eq $meet}
                    if ($25meet) {
                        try {
                            $25meetspan = [timespan]::ParseExact($25meet.time, $timepatterns, [cultureinfo]::CurrentCulture)
                        }
                        catch {
                            Continue
                        }
                        if (-not $First25Span) {
                            $First25Time = $25meet.time
                            $First25Span = $25meetspan
                        }
                        $25meetstr = $25meet.time
                        $obj | Add-Member -MemberType NoteProperty -Name $meet -Value $25meetstr
                        if (-not($Fastest25Span)) {
                            $fastest25str = $25meetstr
                            $Fastest25span = $25meetspan
                            $FastestMeetDate = $25meet.date
                        }
                        elseif ($25meetspan -lt $Fastest25span) {
                            $fastest25str = $25meetstr
                            $Fastest25span = $25meetspan
                            $FastestMeetDate = $25meet.date
                        }
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $meet -Value $null
                    }
                }
                $FastestSpan = $Fastest25span
                $fastesttimestr = $fastest25str
                if ($Fastest25span -lt $50Cutofftime -and $SwimmerData[$swmr]["$($strokename)50"]) {
                    $50events = $SwimmerData[$swmr]["$($strokename)50"]
                    $Fastest50 = $null
                    Write-Verbose "Fetching 50m $strokename times for $swmr"
                    foreach ($meet in $50events) {
                        try {
                            $50meetspan = [timespan]::ParseExact($meet.time, $timepatterns, [cultureinfo]::CurrentCulture)
                        }
                        catch {
                            Continue
                        }
                        if (-not $Fastest50) {
                            $fastest50span = $50meetspan
                            $fastest50Date = $meet.Date
                        }
                        elseif ($50meetspan -lt $fastest50span) {
                            $fastest50span = $50meetspan
                            $fastest50Date = $meet.Date
                        }
                    }
                    $50Halved = $fastest50span.TotalMilliseconds / 2
                    if ($50Halved -lt $Fastest25span.TotalMilliseconds) {
                        $25of50Span = [timespan]::ParseExact($50Halved, 'ssfff', [cultureinfo]::CurrentCulture)
                        $25of50Str = $25of50Span.tostring('ss"."ff')
                        $obj.$fastest50Date = "$25of50Str (50m)"
                        $FastestSpan = $25of50Span
                        $fastesttimestr = $25of50Str
                        $FastestMeetDate = $fastest50Date
                    }
                }
                $improvement = $FastestSpan - $First25Span
                $obj | Add-Member -MemberType NoteProperty -Name FirstTime -Value $First25Time
                $obj | Add-Member -MemberType NoteProperty -Name FastestTime -Value $fastesttimestr
                $obj | Add-Member -MemberType NoteProperty -Name FastestMeetDate -Value $FastestMeetDate
                $obj | Add-Member -MemberType NoteProperty -Name TimeImprovement -Value $improvement.ToString('ss"."ff')
                $array += $obj
            }
        }
    }
    end {
        Write-Output ($array | Sort-Object TimeImprovement -desc)
    }
}
function Get-IMPointsTrophies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData
    )
    begin {
        $IM = $PRCACAwardsConfig['IM']
        $events = @()
        foreach ($distance in $IM['Distances']) {
            $events += "IM$distance"
        }
        $array = @()
    }
    process {
        foreach ($swmr in $SwimmerData.Keys) {
            $strokes = $swimmerdata[$swmr].keys | Where-Object {$_ -in $events}
            if ($strokes) {
                $finalpoints = 0
                write-verbose "Aggregating IM Points for $swmr"
                $swmrage = ($swimmerdata.$swmr.Values.Age | Measure-Object -Maximum).Maximum
                $rangename = ($IM['AgeRanges'].GetEnumerator() | Where-Object {$_.Value -contains $swmrage}).name
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name 'Swimmer' -Value $swmr
                $obj | Add-Member -MemberType NoteProperty -Name 'Age' -Value $swmrage
                $obj | Add-Member -MemberType NoteProperty -Name 'Category' -Value $rangename
                $obj | Add-Member -MemberType NoteProperty -Name 'CategoryPlacing' -Value $null
                foreach ($evt in $events) {
                    if ($evt -in $strokes) {
                        $strokepoints = ($swimmerdata[$swmr][$evt].Points | measure-object -sum).Sum
                        $obj | Add-Member -MemberType NoteProperty -Name $evt -Value $strokepoints
                        $finalpoints += $strokepoints
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $evt -Value $null
                    }
                }
                $obj | Add-Member -MemberType NoteProperty -Name 'TotalPoints' -Value $finalpoints
                if ($finalpoints -gt 0) {
                    $array += $obj
                }

            }
        }
        foreach ($range in $IM['AgeRanges'].Keys) {
            write-verbose "Ranking $range range swimmers"
            $placing = 1
            $groups = $array | Where-Object {$_.Category -eq $range} | Group-Object -Property Totalpoints -AsHashTable
            foreach ($grp in ($groups.Keys | Sort-Object -desc)) {
                $grpcount = $groups[$grp].Count
                foreach ($swmr in $groups[$grp]) {
                    $swmr.categoryplacing = $placing
                }
                $placing += $grpcount
            }
        }
    }
    end {
        write-output ($array | Sort-Object cat*)
    }
}
function Get-PinetathlonTrophies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData
    )
    begin {
        $pinetathlon = $PRCACAwardsConfig['pinetathlon']
        $array = @()
    }
    process {
        $pinestrokes = $pinetathlon['events'].values | ForEach-Object {$_.split(" ")} | Select-Object -Unique
        foreach ($swmr in $SwimmerData.Keys) {
            $swmrage = ($swimmerdata[$swmr].Values.Age | Measure-Object -Maximum).Maximum
            $rangename = ($pinetathlon['AgeRanges'].GetEnumerator() | Where-Object {$_.Value -contains $swmrage}).name
            $swmrpineevents = $SwimmerData[$swmr].Keys | Where-Object {$_ -in $pinetathlon.events.$rangename}
            if ($swmrpineevents.count -eq ($pinetathlon['events'][$rangename].count)) {
                Write-Verbose "Fetching fastest times for Pinetathlon events for $swmr"
                $totaltime = $null
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr
                $obj | Add-Member -MemberType NoteProperty -Name 'Age' -Value $swmrage
                $obj | Add-Member -MemberType NoteProperty -Name 'Category' -Value $rangename
                $obj | Add-Member -MemberType NoteProperty -Name 'CategoryPlacing' -Value $null
                foreach ($stroke in $pinestrokes) {
                    if ($stroke -in $pinetathlon.events.$rangename -and $stroke -in $swmrpineevents) {
                        Write-Verbose "processing $stroke for $swmr"
                        $stroketimes = @()
                        foreach ($i in ($SwimmerData[$swmr][$stroke].time | Where-Object {$_ -ne 'DQ'})) {
                            $stroketimes += [timespan]::ParseExact($i, $timepatterns, [cultureinfo]::CurrentCulture)
                        }
                        $fastesttime = ($stroketimes | Measure-Object -Minimum).Minimum
                        $totaltime += $fastesttime
                        $stroketime = $fastesttime.ToString('mm":"ss"."ff')
                        $obj | Add-Member -MemberType NoteProperty -Name $stroke -Value $stroketime
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $stroke -Value $null
                    }
                }
                $finaltime = $totaltime.ToString('mm":"ss"."ff')
                $obj | Add-Member -MemberType NoteProperty -Name "TotalTime" -Value $finaltime
                $array += $obj
            }
        }
        foreach ($range in $pinetathlon.AgeRanges.Keys) {
            write-verbose "Ranking $range range swimmers"
            $orderedarray = $array | Where-Object {$_.Category -eq $range -and $_.TotalTime -notlike "N/A*"} | Sort-Object TotalTime
            foreach ($obj in $orderedarray) {
                if ($orderedarray.count) {
                    $place = $orderedarray.IndexOf($obj) + 1
                }
                else {
                    $place = 1
                }
                $obj.CategoryPlacing = $place
            }
        }
    }
    end {
        Write-Output ($array | Sort-Object Cat*) 
    }
}
function Get-DistanceTrophies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData
    )
    begin {
        $distance = $PRCACAwardsConfig['Distance']
        $array = @()
    }
    process {
        $strokes = $distance['events'].values | ForEach-Object {$_.split(" ")} | Select-Object -Unique
        foreach ($swmr in $SwimmerData.Keys) {
            $diststrokes = $swimmerdata[$swmr].keys | Where-Object {$_ -in $strokes}
            if ($distStrokes) {
                Write-Verbose "Aggregating distance events points for $swmr"
                $finalpoints = 0
                $swmrage = ($swimmerdata[$swmr].Values.Age | Measure-Object -Maximum).Maximum
                $rangename = ($distance.AgeRanges.GetEnumerator() | Where-Object {$_.Value -contains $swmrage}).name
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr
                $obj | Add-Member -MemberType NoteProperty -Name Age -Value $swmrage
                $obj | Add-Member -MemberType NoteProperty -Name Category -Value $rangename
                $obj | Add-Member -MemberType NoteProperty -Name CategoryPlacing -Value $null
                foreach ($stroke in $strokes) {
                    if ($stroke -in $diststrokes -and $stroke -in $distance.events.$rangename) {
                        $strokepoints = ($swimmerdata.$swmr.$stroke.Points | measure-object -sum).Sum
                        $obj | Add-Member -MemberType NoteProperty -Name $stroke -Value $strokepoints
                        $finalpoints += $strokepoints
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $stroke -Value $null
                    }
                }
                $obj | Add-Member -MemberType NoteProperty -Name TotalPoints -Value $finalpoints
                if ($finalpoints -gt 0) {
                    $array += $obj
                }
            }
        }
        foreach ($range in $distance['AgeRanges'].Keys) {
            write-verbose "Ranking $range range swimmers"
            $placing = 1
            $groups = $array | Where-Object {$_.Category -eq $range} | Group-Object -Property Totalpoints -AsHashTable
            foreach ($grp in ($groups.Keys | Sort-Object -desc)) {
                $grpcount = $groups[$grp].Count
                foreach ($swmr in $groups[$grp]) {
                    $swmr.categoryplacing = $placing
                }
                $placing += $grpcount
            }
        }
    }
    end {
        write-output ($array | Sort-Object cat*)
    }
}
function Get-EnduranceTrophies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData
    )
    Begin {
        $endurance = $PRCACAwardsConfig['Endurance']
        $array = @()
    }
    process {
        foreach ($swmr in $SwimmerData.Keys) {
            $swmrage = ($swimmerdata[$swmr].Values.Age | Measure-Object -Maximum).Maximum
            $strokes = $swimmerdata[$swmr].Keys | Where-Object {$_ -in $endurance['events']}
            if ($strokes.count -ge $endurance['topxevents'] -and $swmrage -ge $endurance['MinAge']) {
                Write-Verbose "Aggregating Endurance points for $swmr"
                $totalpoints = @()
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr
                $obj | Add-Member -MemberType NoteProperty -Name Age -Value $swmrage
                foreach ($evt in $endurance['events']) {
                    if ($evt -in $strokes) {
                        $evtpoints = ($swimmerdata.$swmr.$evt | measure-object -Property points -sum).Sum
                        $obj | Add-Member -MemberType NoteProperty -Name $evt -Value $evtpoints
                        $totalpoints += $evtpoints
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $evt -Value $null
                    }
                }
                $FinalPoints = ($totalpoints | Sort-Object -desc | Select-Object -First $endurance['topxevents'] | Measure-Object -sum).sum
                $obj | Add-Member -MemberType NoteProperty -Name TotalPoints -Value $FinalPoints
                $array += $obj
            }
        }
    }
    End {
        Write-Output ($array | Sort-Object TotalPoints -Descending)
    }
}
function Get-ClubChampion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData,
        [Parameter(Mandatory=$true)]$CategoryPath,
        [Parameter(Mandatory=$true)]$QualTimesPath
    )
    begin {
        $outputarray = @()
        $memberdetails = Import-Csv $CategoryPath
        $qualtimes = import-csv $QualTimesPath
        $clubchamp = $PRCACAwardsConfig['ClubChampion']
        $lastclubnight = Get-LastClubNight $SwimmerData
    }
    Process {
        foreach ($Swimmer in $SwimmerData.Keys) {
            try {
                $SwimmerDetails = Get-SwimmersCategory -SwimmersName $Swimmer -ClubNightDate $lastclubnight -MemberData $memberdetails -Verbose
            }
            catch {
                continue
            }
            if ($SwimmerDetails['Age'] -ge $clubchamp['MinAge']) {
                $swimmerCategory = "$($SwimmerDetails['Age'])$($SwimmerDetails['Gender'])"
                $SwimmerRecord = New-Object psobject
                $SwimmerRecord | Add-Member -MemberType NoteProperty -Name "Swimmer" -Value $Swimmer
                $SwimmerRecord | Add-Member -MemberType NoteProperty -Name "Category" -Value $swimmerCategory
                $SwimmerRecord | Add-Member -MemberType NoteProperty -Name "Place" -Value $null
                $swmrPercentages = @()
                foreach ($evt in $qualtimes.Event) {
                    if ($evt -in $SwimmerData[$swimmer].keys) {
                        $stroketimes = @()
                        foreach ($i in ($SwimmerData[$swimmer][$evt].Time | Where-Object {$_ -ne 'DQ'})) {
                            $stroketimes += [timespan]::ParseExact($i, $timepatterns, [cultureinfo]::CurrentCulture)
                        }
                        Write-Verbose "$($stroketimes.count) count of $($evt) in $($Swimmer)'s Events"
                        $fastesttimespan = ($stroketimes | Measure-Object -Minimum).Minimum
                        $qualtime = ($qualtimes | Where-Object {$_.event -eq $evt}).$swimmerCategory
                        $qualtimespan = [TimeSpan]::FromSeconds($qualtime)
                        $percentdif = $fastesttimespan.TotalMilliseconds / $qualtimespan.TotalMilliseconds * 100
                        $evtpercent = [math]::Round($percentdif,2)
                        $SwimmerRecord | Add-Member -MemberType NoteProperty -Name $evt -Value $evtpercent
                        $swmrPercentages += $evtpercent
                    }
                    else {
                        $SwimmerRecord | Add-Member -MemberType NoteProperty -Name $evt -Value 'N/A'
                    }    
                }
                $outputarray += $SwimmerRecord
                if ($swmrPercentages.count -ge $clubchamp['topxevents']) {
                    $finalpercent = ($swmrPercentages | Sort-Object | Select-Object -First $clubchamp['topxevents'] | Measure-Object -Sum).Sum
                    $SwimmerRecord | Add-Member -MemberType NoteProperty -Name 'TotalPercentage' -Value $finalpercent
                }
                else {
                    $SwimmerRecord | Add-Member -MemberType NoteProperty -Name 'TotalPercentage' -Value 'N/A'
                }
            }
            else {
                Write-Verbose "$swimmer does not qualify for Club Champion"
            }
        }
        $orderedarray = $outputarray | Where-Object {$_.TotalPercentage -ne 'N/A'} | Sort-Object TotalPercentage
        foreach ($obj in $orderedarray) {
            $outobj = $outputarray | Where-Object {$_.Swimmer -eq $obj.Swimmer}
            $place = $orderedarray.IndexOf($obj) + 1
            $outobj.Place = $place
        }
    }
    End {
        Write-Output ($orderedarray | sort place)
    }
}
function Update-AwardsList {
    [CmdletBinding()]
    param (
        # New Awards Data. "Get-NewAchievementAwards" or "Get-TowelAwards" results. 
        [Parameter(Mandatory=$true,Position=0)]$NewAwardData,
        # Awards Data location
        [Parameter(HelpMessage="Path to AwardsList.csv file")]$AwardsListLocation
    )
    begin {
        if (-not $AwardsListLocation) {
            $AwardData = @()
        }
        else {
            $AwardData = Import-csv "$AwardsListLocation\AwardsList.csv"
        }
    }
    process {
        foreach ($swmr in $NewAwardData) {
            $obj = $AwardData | Where-Object {$_.Swimmer -eq $swmr.swimmer}
            if (-not $obj) {
                $obj = New-Object PSObject
                $obj | Add-Member -MemberType NoteProperty -Name Swimmer -Value $swmr.swimmer
                $obj | Add-Member -MemberType NoteProperty -Name AchievementAwards -Value $null
                $obj | Add-Member -MemberType NoteProperty -Name TowelAwards -Value $null
                $AwardData += $obj
                $obj = $AwardData | Where-Object {$_.Swimmer -eq $swmr.swimmer}
            }
            #Achievement Awards
            if ($swmr.AwardsDue -and $obj.achievementawards) {
                $obj.achievementawards += ", $($swmr.AwardsDue)"
            }
            elseif ($swmr.AwardsDue) {
                $obj.achievementawards = "$($swmr.AwardsDue)"
            }
            #Towel Awards
            if ($swmr.AwardStroke) {
                $obj.TowelAwards = "$($swmr.AwardStroke)"
            }
        }
    }
    end {
        Write-Output ($AwardData | Sort-Object Swimmer)
    }
}
function Get-ModifiedData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$CleanedData
    )
    Begin {
        $outputarray = @()
    }
    process {
        foreach ($swimmer in $CleanedData.Keys) {
            foreach ($Stroke in $CleanedData.$Swimmer.Keys) {
                foreach ($Meet in ($CleanedData.$Swimmer.$Stroke.GetEnumerator() | Where-Object {$_.Changed -ne $null})) {
                    $obj = New-Object psobject -Property @{
                        Swimmer = $Swimmer
                        Event = $Stroke
                        Date = $meet.date
                        Age = $meet.Age
                        pb = $meet.pb
                        Time = $meet.time
                        seedTime = $meet.seedtime
                        Points = $meet.points
                        Changed = $meet.Changed                        
                    }
                    $outputarray += $obj
                }
            }
        }
    }
    end {
        Write-Output ($outputarray | Sort-Object Swimmer, Event, Date)
    }
}
function Get-SwimmersEvents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmerData,
        [Parameter(Mandatory=$true,Position=1)]$SwimmersName,
        [Parameter()]$EventName
    )
    Begin {
        $outputarray = @()
        if ($EventName) {
            $Strokefilter = $EventName
        }
        else {
            $Strokefilter = "*"
        }
    }
    process {
        foreach ($Stroke in $SwimmerData.$SwimmersName.Keys) {
            if ($Stroke -like $Strokefilter) {
                foreach ($Meet in $SwimmerData.$SwimmersName.$Stroke) {
                    if ($meet.count -ne 1) {
                        $obj = New-Object psobject -Property @{
                            Swimmer = $SwimmersName
                            Event = $Stroke
                            Date = $meet.date
                            Age = $meet.Age
                            pb = $meet.pb
                            Time = $meet.time
                            seedTime = $meet.seedtime
                            Points = $meet.points
                            Changed = $meet.Changed                        
                        }
                        $outputarray += $obj
                    }
                }   
            }
        }
    }
    end {
        Write-Output ($outputarray | Sort-Object Event, Date)
    }
}
function Get-LastClubNight {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]$SwimData
    )
    Process {
        $ClubNight = [string](($SwimData.Values.values.date | measure -Maximum).Maximum)
    }
    End {
        Write-Output $ClubNight
    }
}
function Get-SwimmersCategory {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0)]$SwimmersName,
        [Parameter(Mandatory=$true,Position=1)]$ClubNightDate,
        [Parameter(Mandatory=$true,Position=2)]$MemberData
    )
    Begin {
        $SwimmersInfo = @{}
    }
    Process {
        $lastClubNight = [Datetime]::ParseExact([string]$clubnightdate, 'yyMMdd', $null)
        $firstLast = $SwimmersName.split(",")
        $gn = $firstLast[1].Trim()
        $sn = $firstLast[0].Trim()
        $swimmersDetails = $MemberData | where {($_."Last Name").trim() -eq $sn -and ($_."First Name").trim() -eq $gn}
        if (-not $swimmersDetails) {
            Write-Verbose "No member data for $($SwimmersName) - check firstname/lastname and spelling."
            Continue
        }
        $dob = [Datetime]::ParseExact($swimmersDetails.BirthDate, 'dd/MM/yyyy', $null)
        #have they had their birthday this year? if so, get age from this year, else get the age from last year
        if (($lastClubNight.DayOfYear - $dob.DayOfYear) -ge 0) {
            $SwimmersAge = $lastClubNight.Year - $dob.Year
        }
        else {
            $SwimmersAge = ($lastClubNight.Year - 1) - $dob.Year
        }
        if ($swimmersDetails.Gender -eq "Female") {
            $SwimmersGender = "Girls"
        }
        else {
            $SwimmersGender = "Boys"
        }
        $SwimmersInfo['Age'] = $SwimmersAge
        $SwimmersInfo['Gender'] = $SwimmersGender
    }
    End {
        Write-Output $SwimmersInfo
    }
}
[String[]]$timepatterns = @(
            'sssfff'
            'ssfff'
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
Export-ModuleMember -function Get-SwimmersCategory
Export-ModuleMember -Function Get-LastClubNight