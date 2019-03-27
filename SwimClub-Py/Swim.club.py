PRCACAwardsConfig = {
    "Points" : {
        "Regular" : {
            #All Below are 1 Point
            "2points": "02.49",
            "3points": "01.49",
            "4points": "00.49",
            "5points": "01.49",
            "6points": "02.49",
            "7points": "04.99"
            #All above are 8 Points
        },
        "Endurance" : {
            #All Below are 1 Point
            "3points" : "14.99",
            "4points" : "09.99",
            "5points" : "04.99",
            "6points" : "09.99"
            #All above are 7 Points
        }
    },
    "Achievement" : {
        "PBsPerAward" : 3
    },
    "Towel" : {
        "AgeRanges" : {
            "7andUnder" : range(4,8),
            "8and9" : range(8,10),
            "10and11" : range(10,12),
            "12andOver" : range(12,18)
        },
        "Distances" : ["25", "50", "100"],
        "MinPoints" : 16
    },
    "AggregatePoints" : {
        "Events" : {
            "Backstroke" : ["25", "50", "100"],
            "Breaststroke" : ["25", "50", "100"],
            "Butterfly" : ["25", "50", "100"],
            "Freestyle" : ["25", "50", "100", "200", "400"]
        },
        "AgeRanges" : {
            "7andUnder" : range(4,8),
            "8and9" : range(8,10),
            "10andOver" : range(10,18),
        },
        "TopPercentAwarded" : 25
    },
    "25Improvement" : {
        "ProgressTimes" : {
            "Backstroke" : "28.00",
            "Breaststroke" : "29.00",
            "Butterfly" : "25.00",
            "Freestyle" : "25.00"
        }
    },
    "IM" : {
        "Distances" : ["100", "200"],
        "AgeRanges" : {
            "9andUnder" : range(4,10),
            "10and11" : range(10,12),
            "12andOver" : range(12,18)
        }
    },
    "Pinetathlon" : {
        "AgeRanges" : {
            "9andUnder" : range(4,10),
            "10and11" : range(10,12),
            "12andOver" : range(12,18)
        },
        "Events" : {
            "9andUnder" : ["Freestyle100", "Freestyle200", "Backstroke100", "Breaststroke100", "IM100", "Butterfly50"],
            "10and11" : ["Freestyle100", "Freestyle200", "Backstroke100", "Breaststroke100", "IM100", "Butterfly50"],
            "12andOver" : ["Freestyle100", "Freestyle200", "Backstroke100", "Breaststroke100", "IM200", "Butterfly100"]
        }
    },
    "Distance" : {
        "AgeRanges" : {
            "Junior" : range(4,12),
            "Senior" : range(12,18)
        },
        "Events" : {
            "Junior" : "Freestyle200",
            "Senior" : ["Freestyle200", "Freestyle400"]
        }
    },
    "Endurance" : {
        "MinAge" : 11,
        "TopXEvents" : 4,
        "Events" : ["IM400", "Freestyle800", "Backstroke200", "Breaststroke200", "Butterfly200"]
    }
}
def TimePatterns(timestr):
    if ":" in timestr:
        pattern = "%M:%S.%f"
    elif "." not in timestr:
        pattern = "%S"
    else:
        pattern = "%S.%f"
    return pattern

def ToSeconds(timestr):
    if ":" in timestr:
        strsplit = timestr.split(':')
        totalseconds = (float(strsplit[0]) * 60 + float(strsplit[1]))
    else:
        totalseconds = float(timestr)
    return totalseconds

def SwimmerData(csv_path):
    from re import sub
    from csv import DictReader
    from pathlib import Path
    #get the CSV file names from the path
    files = list(Path(csv_path).glob("*.csv"))
    swimmers = {}
    for file in files:
        meetdate = file.stem[file.stem.index("_")+1:len(file.stem)]
        if ("clubnight" in file.stem):
            csv_data = DictReader(open(file), fieldnames=range(1,186))
            SwimmerCol = 125
            AgeCol = 126
            SeedCol = 128
            TimeCol = 131
            PointsCol = 134
            EventCol = 8
            DistIndex = (0-1) #Event Distance relative to 'SC' in string
            StrokeIndex = (0+2) #Event name relative to 'SC' in string
            filetype = "Meet"
        elif ("clubchamps" in file.stem):
            continue
        else:
            csv_data = DictReader(open(file))
            eventname = file.stem[0:file.stem.index("_")]
            filetype = "Event"
        for line in csv_data:
            if filetype == "Meet":
                rawevent = sub('"','',line[EventCol]).split(' ')
                scindex = rawevent.index('SC')
                eventname = f"{rawevent[scindex + StrokeIndex]}{rawevent[scindex + DistIndex]}"
                swimmer = sub('"','',line[SwimmerCol])
                age = int(sub('"','',line[AgeCol]).strip())
                seed = sub('"','',line[SeedCol])
                time = sub('"','',line[TimeCol])
                rawpoints = sub('"','',line[PointsCol])
                try:
                    points = int(rawpoints)
                except:
                    points = None
            else:
                swimmer = sub(r'[^a-zA-Z ,-]','',line['Name']).strip()
                try:
                    age = int(sub(r'[^0-9]','',line['Age']).strip())
                except ValueError:
                    age = None
                seed = line['SeedTime']
                time = line['Time']
                try:
                    points = int(line['Points'])
                except:
                    points = None
            if not ("," in swimmer):
                surname = swimmer.split(" ")[1]
                firstname = swimmer.split(" ")[0]
                swimmer = f"{surname}, {firstname}"
            try:
                swimmers[swimmer]
            except KeyError:
                swimmers[swimmer] = {}
            try:
                swimmers[swimmer][eventname]
            except KeyError:
                swimmers[swimmer][eventname] = []
            obj = {
                "Date": meetdate,
                "Age": age,
                "pb": None,
                "Time": time,
                "seedTime": seed,
                "Points": points,
                "Changed": None
            }
            swimmers[swimmer][eventname].append(obj)
    return swimmers

def ConfirmData(SwimmerData):
    from datetime import datetime, timedelta
    #setup config & timedeltas
    enduranceDist = PRCACAwardsConfig['Endurance']['Events']
    ptsdefs = PRCACAwardsConfig['Points']
    timedeltas = {}
    for cat in ptsdefs.keys():
        timedeltas[cat] = {}
        for lvl in ptsdefs[cat].keys():
            keystr = f"{lvl[0]}ptTimeDelta"
            timedeltas[cat][keystr] = timedelta(seconds=ToSeconds(ptsdefs[cat][lvl]))
    #loop through swimmerdata
    for swmr, strokes in SwimmerData.items():
        for stroke, meets in strokes.items():
            if stroke in enduranceDist:
                endurance = True
                pnts = timedeltas['Endurance']
            else:
                endurance = False
                pnts = timedeltas['Regular']         
            meets.sort(key=lambda k: k['Date'])
            seedtime = None
            for i in range(0,len(meets)):
                change = None
                points = None
                try:
                    meettimespan = timedelta(seconds=ToSeconds(meets[i]['Time']))
                except:
                    continue
                if seedtime == None and meets[i]['seedTime'] != 'NT':
                    seedtime = meets[i]['seedTime']
                    seedtimespan = timedelta(seconds=ToSeconds(seedtime))
                #else if the carried seedtime is not the same as the current, change it.
                elif seedtime != None and meets[i]['seedTime'] != seedtime:
                    meets[i]['seedTime'] = seedtime
                    change = 'SeedTime'
                #----------------------------------------------------------------------
                #                         MAIN POINTS LOGIC
                #----------------------------------------------------------------------
                #1st event?
                if seedtime == None and meets[i]['seedTime'] == 'NT':
                    seedtime = meets[i]['Time']
                    seedtimespan = timedelta(seconds=ToSeconds(seedtime))
                    meets[i]['pb'] = 'No'
                    if endurance:
                        points = 4
                    else:
                        points = None
                #slower than pb
                elif meettimespan > seedtimespan:
                    timedif = meettimespan - seedtimespan
                    #endurance PAR is 5 points
                    if endurance and timedif <= pnts['5ptTimeDelta']:
                        points = 5
                    elif timedif <= pnts['4ptTimeDelta']:
                        points = 4
                    elif timedif <= pnts['3ptTimeDelta']:
                        points = 3
                    #no 2point range for endurance
                    elif not endurance and timedif <= pnts['2ptTimeDelta']:
                        points = 2
                    else:
                        points = 1
                    meets[i]['pb'] = 'No'
                #faster than pb
                elif meettimespan < seedtimespan:
                    timedif = seedtimespan - meettimespan
                    #regular PAR is 4 points
                    if not endurance and timedif <= pnts['4ptTimeDelta']:
                        points = 4
                    elif timedif <= pnts['5ptTimeDelta']:
                        points = 5
                    elif timedif <= pnts['6ptTimeDelta']:
                        points = 6
                    elif endurance or timedif <= pnts['7ptTimeDelta']:
                        points = 7
                    else:
                        points = 8
                    meets[i]['pb'] = 'Yes'
                    seedtime = meets[i]['Time']
                    seedtimespan = timedelta(seconds=ToSeconds(seedtime))
                else:
                    meets[i]['pb'] = 'No'
                    points = 4
                if meets[i]['Points'] != points and change == None:
                    change = 'Points'
                elif meets[i]['Points'] != points and change != None:
                    change = f'{change}, Points'
                meets[i]['Changed'] = change
                meets[i]['Points'] = points
    #return the results in the award_data object
    return SwimmerData

def AchievementAwards(SwimmerData, AwardListLocation = None):
    from csv import DictReader
    pbnum = PRCACAwardsConfig['Achievement']['PBsPerAward']
    try:
        AwardFile = f"{AwardListLocation}\AwardsList.csv"
        AwardsList = DictReader(open(AwardFile))
    except:
        AwardsList = None
    outputobj = {}
    for swimmer, strokes in SwimmerData.items():
        pbtable = {}
        AwardsDue = []
        for stroke, meets in strokes.items():
            pbcount = 0
            for meet in meets:
                if meet['pb'] == 'Yes':
                    pbcount += 1
            pbtable[stroke] = pbcount
        for stroke, pbs in pbtable.items():
            # set the pb number
            totalpbs = pbs
            # 25m efforts carry over to the 50m equivilent
            if ('50' in stroke):
                try:
                    pbs25 = pbtable[stroke.replace('50','25')] % pbnum
                    if pbs25 in range(1,pbnum - 1):
                        slash25 = True
                        totalpbs = pbs + pbs25
                    else:
                        slash25 = False
                except:
                    slash25 = False
            else:
                slash25 = False
            # Only continue if there are 3 or more pbs
            if totalpbs >= pbnum:
                # First Achievement award level (pbnum*1)
                if totalpbs >= pbnum and slash25:
                    AwardsDue.append(f"{stroke.replace('50','25')}/50")
                else:
                    AwardsDue.append(stroke)
                # Second Achievement award level (pbnum*2)
                if totalpbs >= (pbnum  * 2) and slash25:
                    AwardsDue.append(stroke)
                elif totalpbs >= (pbnum  * 2):
                    AwardsDue.append(f"{stroke}(#2)")
                # Third Achievement award level (pbnum*3)
                if totalpbs >= (pbnum  * 3) and slash25:
                    AwardsDue.append(f"{stroke}(#2)")
                elif totalpbs >= (pbnum  * 3):
                    AwardsDue.append(f"{stroke}(#3)")
        if len(AwardsDue) > 0:
            newawards = ''
            if AwardsList != None:
                for line in AwardsList:
                    if line['Swimmer'] == swimmer:
                        swmrawards = line
            else:
                swmrawards = ''
            for award in AwardsDue:
                if award not in swmrawards and newawards == '':
                    newawards += award
                elif award not in swmrawards and newawards != '':
                    newawards += f", {award}"
            if newawards != None:
                outputobj[swimmer] = newawards
    return outputobj

def TowelAwards(SwimmerData, Strokename, AwardListLocation, StartDate, NumberofWeeks = 4):
    from datetime import datetime, timedelta
    from csv import DictReader
    towel = PRCACAwardsConfig['Towel']
    StartList = StartDate.split('/')
    yearstr = f"20{StartList[2]}"
    FirstClubNight = datetime(year=int(yearstr),month=int(StartList[1]),day=int(StartList[0]))
    aWeek = timedelta(days=7)
    filters = []
    for i in range(0,NumberofWeeks):
        ClubNight = FirstClubNight + (aWeek * i)
        filters.append(ClubNight.strftime('%y%m%d'))
    events = []
    for distance in towel['Distances']:
        events.append(f"{Strokename}{distance}")
    pointslist = []
    outputlist = []
    try:
        AwardFile = f"{AwardListLocation}\AwardsList.csv"
        with open(AwardFile) as csv:
            AwardsList = DictReader(open(AwardFile))
            previousrecips = [i['Swimmer'] for i in AwardsList if i['TowelAwards'] != '']
    except:
        quit
    for swmr, strokes in SwimmerData.items():
        if swmr in previousrecips:
            print(f'{swmr} bypassed')
            continue
        else:
            print(f'{swmr} evaluated')
            swmrevents = [stroke for stroke in strokes.keys() if stroke in events]
            points = 0
            agelist = []
            for evt in swmrevents:
                agelist.append(max(i['Age'] for i in strokes[evt]))
                for meet in strokes[evt]:
                    if meet['Points'] != None and meet['Date'] in filters:
                        points += meet['Points']
            swmrage = int(max(agelist))
            if points >= towel['MinPoints']:
                pointslist.append({'Swimmer': swmr, 'Age': swmrage, 'Points': points})
    for rangename, agesinrange in towel['AgeRanges'].items():
        rangeswimmers = [i for i in pointslist if i['Age'] in agesinrange]
        if rangeswimmers != []:
            toppoints = max(i['Points'] for i in rangeswimmers)
            topswmrs = [i for i in rangeswimmers if i['Points'] == toppoints]
            for x in topswmrs:
                outputlist.append({'AgeGroup': rangename, 'Swimmer': x['Swimmer'], 'Points': x['Points']})
    return outputlist
                
def AggregatePoints(SwimmerData):
    Aggpoints = PRCACAwardsConfig['AggregatePoints']
    outputlist = []
    filters = []
    for evt, Distances in Aggpoints['Events'].items():
        evtlist = [f"{evt}{dist}" for dist in Distances]
        for evt in evtlist:
            filters.append(evt)
    for swmr, strokes in SwimmerData.items():
        agelist = []
        events = [stroke for stroke in strokes.keys() if stroke in filters]
        swmrpoints = 0
        for evt in events:
            evtpoints = sum(i['Points'] for i in SwimmerData[swmr][evt] if i['Points'] != None)
            swmrpoints += evtpoints
            agelist.append(max([i['Age'] for i in SwimmerData[swmr][evt] if isinstance(i['Age'],int)]))
        swmrage = max(agelist)
        rangename = [k for k, v in Aggpoints['AgeRanges'].items() if swmrage in v][0]
        obj = {
            'Swimmer': swmr,
            'Category': rangename,
            'Age': swmrage,
            'Points': swmrpoints,
            'CategoryPlacing': None,
            'Trophy': None
        }
        outputlist.append(obj)
    for cat in Aggpoints['AgeRanges'].keys():
        placing = 1
        CatSwmrs = [i for i in outputlist if i['Category'] == cat]
        trophyplaces = round(len(CatSwmrs) * (Aggpoints['TopPercentAwarded']/100))
        catpoints = sorted(set([i['Points'] for i in CatSwmrs]),reverse=True)
        for i in catpoints:
            placegetters = [c for c in CatSwmrs if c['Points'] == i]
            for p in placegetters:
                if placing in range(1,(trophyplaces+1)):
                    p['CategoryPlacing'] = placing
                    p['Trophy'] = 'Yes'
                else:
                    p['CategoryPlacing'] = placing
            placing += len(placegetters)
    return outputlist

def Improvement25(SwimmerData, Strokename):
    from datetime import datetime, timedelta
    improve25 = PRCACAwardsConfig['25Improvement']
    promotetimespan = datetime.strptime(improve25['ProgressTimes'][Strokename], TimePatterns(improve25['ProgressTimes'][Strokename]))
    outputlist = []
    meetdates = []
    for k, v in SwimmerData.items():
        for i in v.values():
            meetdates = meetdates + [x['Date'] for x in i]
    meets = sorted(set(meetdates))
    for swmr, strokes in SwimmerData.items():
        if f"{Strokename}25" in strokes.keys():
            obj = {
                'Swimmer': swmr,
            }
            fastest25span = None
            first25span = None
            for meet in meets:
                meet25 = [m for m in SwimmerData[swmr][f"{Strokename}25"] if m['Date'] == meet]
                if meet25 != []:
                    try:
                        meet25span = datetime.strptime(meet25[0]['Time'], TimePatterns(meet25[0]['Time']))
                    except:
                        continue
                    if not first25span:
                        first25Time = meet25[0]['Time']
                        first25span = meet25span
                    meet25str = meet25[0]['Time']
                    obj[meet] = meet25str
                    if not fastest25span:
                        fastest25str = meet25str
                        fastest25span = meet25span
                        fastestmeetdate = meet25[0]['Date']
                    elif meet25span < fastest25span:
                        fastest25str = meet25str
                        fastest25span = meet25span
                        fastestmeetdate = meet25[0]['Date']
                else:
                    obj[meet] = None
            fastestspan = fastest25span
            fastesttimestr = fastest25str
            try:
                events50 = SwimmerData[swmr][f"{Strokename}50"]
                swmr50 = True
            except KeyError:
                swmr50 = False
            if fastest25span < promotetimespan and swmr50:
                fastest50 = None
                for meet in events50:
                    try:
                        meet50span = datetime.strptime(meet['Time'], TimePatterns(meet['Time']))
                    except:
                        continue
                    if not fastest50:
                        fastest50span = meet50span
                        fastest50date = meet['Date']
                    elif meet50span < fastest50span:
                        fastest50span = meet50span
                        fastest50date = meet['Date']
                zerospan = datetime.strptime('0', TimePatterns('0'))
                halved50 = (fastest50span - zerospan) / 2
                if halved50 < (fastest25span - zerospan):
                    str25of50 = str(halved50.total_seconds())
                    span25of50 = datetime.strptime(str25of50, TimePatterns(str25of50))
                    obj[fastest50date] = f"{str25of50} (50m)"
                    fastestspan = span25of50
                    fastesttimestr = str25of50
                    fastestmeetdate = fastest50date
            improvement = str((fastestspan - first25span).total_seconds())
            obj['FirstTime'] = first25Time
            obj['FastestTime'] = fastesttimestr
            obj['FastestMeetDate'] = fastestmeetdate
            obj['TimeImprovement'] = improvement
            outputlist.append(obj)
    return (sorted(outputlist, key = lambda x: x['TimeImprovement']))


def WriteAwardCsv(awarddata, awardname, csvpath):
    with open(f"{csvpath}\\{awardname}.csv", 'w', newline='') as csvfile:
        fieldnames = [k for k in awarddata[0].keys()]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for obj in outputlist:
            writer.writerow(obj)

def IMTrophy(SwimmerData):
    im = PRCACAwardsConfig['IM']
    events = [f"IM{d}" for d in im['Distances']]
    outputlist = []
    for swmr in SwimmerData.keys():
        strokes = [i for i in SwimmerData[swmr].keys() if i in events]
        if strokes != []:
            agelist = []
            finalpoints = 0
            obj = {
                'Swimmer': swmr,
                'Age': None,
                'Category': None,
                'CategoryPlacing': None
            }
            for evt in events:
                if evt in strokes:
                    strokepoints = sum([e['Points'] for e in SwimmerData[swmr][evt] if isinstance(e['Points'],int)])
                    strokeage = max([e['Age'] for e in SwimmerData[swmr][evt] if isinstance(e['Age'],int)])
                    obj[evt] = strokepoints
                    finalpoints += strokepoints
                    agelist.append(strokeage)
                else:
                    obj[evt] = None
            cat = [k for k, v in im['AgeRanges'].items() if max(agelist) in v]
            obj['Age'] = max(agelist)
            obj['Category'] = cat[0]
            obj['TotalPoints'] = finalpoints
            outputlist.append(obj)
    for cat in im['AgeRanges'].keys():
            placing = 1
            CatSwmrs = [i for i in outputlist if i['Category'] == cat]
            catpoints = sorted(set([i['TotalPoints'] for i in CatSwmrs]),reverse=True)
            for i in catpoints:
                placegetters = [c for c in CatSwmrs if c['TotalPoints'] == i]
                for p in placegetters:
                    p['CategoryPlacing'] = placing
                placing += len(placegetters)
    return sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

def Pinetathlon(SwimmerData):
    from datetime import timedelta
    pinetathlon = PRCACAwardsConfig['Pinetathlon']
    outputlist = []
    allevents = []
    for i in pinetathlon['Events'].values():
        allevents.extend(i)
    pinestrokes = set(allevents)
    for swmr, strokes in SwimmerData.items():
        ages = []
        for stroke in strokes.values():
            ages.append(max([m['Age'] for m in stroke]))
        swmrage = max(ages)
        rangename = [k for k, v in pinetathlon['AgeRanges'].items() if swmrage in v][0]
        swmrpineevents = [s for s in strokes.keys() if s in pinetathlon['Events'][rangename]]
        if len(swmrpineevents) == len(pinetathlon['Events'][rangename]):
            totaltime = timedelta(seconds=0)
            obj = {
                'Swimmer': swmr,
                'Age': swmrage,
                'Category': rangename,
                'CategoryPlacing': None
            }
            for stroke in pinestrokes:
                if stroke in swmrpineevents:
                    stroketimes = []
                    stroketimes.extend([timedelta(seconds=ToSeconds(m['Time'])) for m in SwimmerData[swmr][stroke] if m['Time'] != 'DQ'])
                    fastesttime = min(stroketimes)
                    totaltime += fastesttime
                    obj[stroke] = str(fastesttime).lstrip('0:').rstrip('0000')
                else:
                    obj[stroke] = None
            obj['TotalTime'] = str(totaltime).lstrip('0:').rstrip('0000')
            outputlist.append(obj)
    for cat in pinetathlon['AgeRanges'].keys():
        placing = 1
        CatSwmrs = [i for i in outputlist if i['Category'] == cat]
        cattimes = sorted(set([timedelta(seconds=ToSeconds(i['TotalTime'])) for i in CatSwmrs]))
        for i in cattimes:
            placegetters = [c for c in CatSwmrs if timedelta(seconds=ToSeconds(c['TotalTime'])) == i]
            for p in placegetters:
                p['CategoryPlacing'] = placing
            placing += len(placegetters)
    return sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

def Distance(SwimmerData):
    distance = PRCACAwardsConfig['Distance']
    outputlist = []
    allevents = []
    for i in distance['Events'].values():
        if isinstance(i, str):
            allevents.append(i)
        elif isinstance(i, list):
            allevents.extend(i)
    diststrokes = set(allevents)
    for swmr, strokes in SwimmerData.items():
        ages = []
        for stroke in strokes.values():
            ages.append(max([m['Age'] for m in stroke]))
        swmrage = max(ages)
        rangename = [k for k, v in distance['AgeRanges'].items() if swmrage in v][0]
        swmrdiststrokes = [s for s in strokes.keys() if s in distance['Events'][rangename]]
        if swmrdiststrokes != []:
            finalpoints = 0
            ages = []
            for stroke in strokes.values():
                ages.append(max([m['Age'] for m in stroke]))
            swmrage = max(ages)
            rangename = [k for k, v in distance['AgeRanges'].items() if swmrage in v][0]
            obj = {
                'Swimmer': swmr,
                'Age': swmrage,
                'Category': rangename,
                'CategoryPlacing': None
            }
            for ds in diststrokes:
                if ds in strokes.keys() and ds in distance['Events'][rangename]:
                    strokepoints = sum([s['Points'] for s in SwimmerData[swmr][ds] if isinstance(s['Points'], int)])
                    obj[ds] = strokepoints
                    finalpoints += strokepoints
                else:
                    obj[ds] = None
            obj['TotalPoints'] = finalpoints
            outputlist.append(obj)
    for cat in distance['AgeRanges'].keys():
        placing = 1
        CatSwmrs = [i for i in outputlist if i['Category'] == cat]
        catpoints = sorted(set([i['TotalPoints'] for i in CatSwmrs]),reverse=True)
        for i in catpoints:
            placegetters = [c for c in CatSwmrs if c['TotalPoints'] == i]
            for p in placegetters:
                p['CategoryPlacing'] = placing
            placing += len(placegetters)
    return sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

def Endurance(SwimmerData):
    endurance = PRCACAwardsConfig['Endurance']
    outputlist = []
    for swmr, strokes in SwimmerData.items():
        ages = []
        for stroke in strokes.values():
            ages.append(max([m['Age'] for m in stroke]))
        swmrage = max(ages)
        swmrendevents = [e for e in strokes.keys() if e in endurance['Events']]
        if len(swmrendevents) >= endurance['TopXEvents'] and swmrage >= endurance['MinAge']:
            TotalPoints = []
            obj = {
                'Swimmer': swmr,
                'Age': swmrage,
                'Placing': None
            }
            for evt in endurance['Events']:
                if evt in swmrendevents:
                    evtpoints = sum([e['Points'] for e in SwimmerData[swmr][evt] if isinstance(e['Points'], int)])
                    obj[evt] = evtpoints
                    TotalPoints.append(evtpoints)
                else:
                    obj[evt] = None
            TotalPoints.remove(min(TotalPoints))
            obj['TotalPoints'] = sum(TotalPoints)
            outputlist.append(obj)
    endpoints = sorted(set([i['TotalPoints'] for i in outputlist]),reverse=True)
    placing = 1
    for i in endpoints:
        placegetters = [s for s in outputlist if s['TotalPoints'] == i]
        for p in placegetters:
            p['Placing'] = placing
        placing += len(placegetters)
    return sorted(outputlist, key = lambda x: x['Placing'])

    def ClubChampion(SwimmerData):
        outputlist = []
        for swmr, strokes in SwimmerData.items():
            swmrpoints = []
            for stroke in strokes.values():
                swmrpoints.append(sum([e['Points'] for e in stroke if isinstance(e['Points'], int)]))
            obj = {
                'Placing': None,
                'Swimmer': swmr,
                'TotalPoints': sum(swmrpoints)
            }
            outputlist.append(obj)
        champpoints = sorted(set([i['TotalPoints'] for i in outputlist]),reverse=True)
        placing = 1
        for i in champpoints:
            placegetters = [s for s in outputlist if s['TotalPoints'] == i]
            for p in placegetters:
                p['Placing'] = placing
            placing += len(placegetters)
        return sorted(outputlist, key = lambda x: x['Placing'])


def UpdateAwardsList(newData, csvpath = None):
from csv import DictReader, DictWriter
if csvpath:
    csvdata = []
    with open(f'{csvpath}\\AwardsList.csv') as csvfile:
        for line in DictReader(csvfile):
            csvdata.append(line)








