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
                age = sub('"','',line[AgeCol]).strip()
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
                    age = ""
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
            secs = int(ptsdefs[cat][lvl].split('.')[0])
            millis = int(ptsdefs[cat][lvl].split('.')[1])*10
            keystr = f"{lvl[0]}ptTimeDelta"
            valdelta = timedelta(seconds=secs,milliseconds=millis)
            timedeltas[cat][keystr] = valdelta
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
                    meettimespan = datetime.strptime(meets[i]['Time'], TimePatterns(meets[i]['Time']))
                except:
                    continue
                if seedtime == None and meets[i]['seedTime'] != 'NT':
                    seedtime = meets[i]['seedTime']
                    seedtimespan = datetime.strptime(seedtime, TimePatterns(seedtime))
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
                    seedtimespan = datetime.strptime(seedtime, TimePatterns(seedtime))
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
                    seedtimespan = datetime.strptime(seedtime, TimePatterns(seedtime))
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
    filters.append(i for i in evtlist)          






def UpdateAwardsList(csv_path):
    pass

