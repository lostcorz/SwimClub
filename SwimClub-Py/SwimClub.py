class PRCACAwards(object):
    config = {
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
                "10andOver" : range(10,18)
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

    @staticmethod
    def ToSeconds(timestr):
        if ":" in timestr:
            strsplit = timestr.split(':')
            totalseconds = (float(strsplit[0]) * 60 + float(strsplit[1]))
        else:
            totalseconds = float(timestr)
        return totalseconds

    def __init__(self, Season):
        SwimClubPath = 
        from re import sub
        from csv import DictReader
        from pathlib import Path
        self.SwimClubPath = SwimClubPath
        self.Season = Season
        self.Trophies = {}
        self.Awards = {}
        #get the CSV file names from the path
        csv_path = f'{SwimClubPath}\\{Season}\\Data'
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
        self.data = swimmers
        
    def ConfirmData(self):
        from datetime import timedelta
        #setup config & timedeltas
        enduranceDist = PRCACAwards.config['Endurance']['Events']
        ptsdefs = PRCACAwards.config['Points']
        timedeltas = {}
        for cat in ptsdefs.keys():
            timedeltas[cat] = {}
            for lvl in ptsdefs[cat].keys():
                keystr = f"{lvl[0]}ptTimeDelta"
                timedeltas[cat][keystr] = timedelta(seconds=(PRCACAwards.ToSeconds(ptsdefs[cat][lvl])))
        #loop through swimmerdata
        for swmr, strokes in self.data.items():
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
                        meettimespan = timedelta(seconds=(PRCACAwards.ToSeconds(meets[i]['Time'])))
                    except:
                        continue
                    if seedtime == None and meets[i]['seedTime'] != 'NT':
                        seedtime = meets[i]['seedTime']
                        seedtimespan = timedelta(seconds=(PRCACAwards.ToSeconds(seedtime)))
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
                        seedtimespan = timedelta(seconds=(PRCACAwards.ToSeconds(seedtime)))
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
                        seedtimespan = timedelta(seconds=(PRCACAwards.ToSeconds(seedtime)))
                    else:
                        meets[i]['pb'] = 'No'
                        points = 4
                    if meets[i]['Points'] != points and change == None:
                        change = 'Points'
                    elif meets[i]['Points'] != points and change != None:
                        change = f'{change}, Points'
                    meets[i]['Changed'] = change
                    meets[i]['Points'] = points
                    if change != None:
                        try:
                            self.ChangedData
                        except:
                            self.ChangedData = []
                        obj = {
                            'Swimmer': swmr,
                            'Event': stroke,
                            "Date": meets[i]['Date'],
                            "Age": meets[i]['Age'],
                            "pb": meets[i]['pb'],
                            "Time": meets[i]['Time'],
                            "seedTime": meets[i]['seedTime'],
                            "Points": points,
                            "Changed": change
                        }
                        self.ChangedData.append(obj)

    def Achievement(self):
        from csv import DictReader
        from pathlib import Path
        pbnum = PRCACAwards.config['Achievement']['PBsPerAward']
        AwardFile = f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\AwardsList.csv'
        filetest = Path(AwardFile).exists()
        if filetest:
            AwardsList = []
            with open(AwardFile) as csvfile:
                for line in DictReader(csvfile):
                    AwardsList.append(line)
        else:
            AwardsList = None
        outputlist = []
        for swimmer, strokes in self.data.items():
            pbtable = {}
            AwardsDue = []
            dates = []
            for stroke, meets in strokes.items():
                pbcount = 0
                for meet in meets:
                    dates.append(meet['Date'])
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
                    try:
                        swmrawards = [line['AchievementAwards'] for line in AwardsList if line['Swimmer'] == swimmer]
                    except:
                        swmrawards = ''
                else:
                    swmrawards = ''
                for award in AwardsDue:
                    if award not in swmrawards and newawards == '':
                        newawards += award
                    elif award not in swmrawards and newawards != '':
                        newawards += f", {award}"
                if newawards != '':
                    outputlist.append({'Swimmer': swimmer, 'AchievementAwards': newawards, 'Date': max(dates)})
        self.Awards['Achievement'] = outputlist
    
    def Towel(self, Strokename, StartDate, NumberofWeeks = 4):
        from datetime import datetime, timedelta
        from csv import DictReader
        from pathlib import Path
        towel = PRCACAwards.config['Towel']
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
        AwardFile = f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\AwardsList.csv'
        try:
            with open(AwardFile) as csv:
                AwardsList = DictReader(csv)
                previousrecips = [i['Swimmer'] for i in AwardsList if i['TowelAwards'] != '']
        except:
            quit
        for swmr, strokes in self.data.items():
            if swmr in previousrecips:
                continue
            else:
                swmrevents = [stroke for stroke in strokes.keys() if stroke in events]
                points = 0
                agelist = []
                for evt in swmrevents:
                    for meet in strokes[evt]:
                        if meet['Points'] != None and meet['Date'] in filters:
                            points += meet['Points']
                            agelist.append(meet['Age'])
                if points >= towel['MinPoints']:
                    swmrage = max(agelist)
                    pointslist.append({'Swimmer': swmr, 'Age': swmrage, 'Points': points})
        for rangename, agesinrange in towel['AgeRanges'].items():
            rangeswimmers = [i for i in pointslist if i['Age'] in agesinrange]
            if rangeswimmers != []:
                toppoints = max(i['Points'] for i in rangeswimmers)
                topswmrs = [i for i in rangeswimmers if i['Points'] == toppoints]
                for x in topswmrs:
                    outputlist.append({'AgeGroup': rangename, 'Swimmer': x['Swimmer'], 'Points': x['Points'], 'Stroke': Strokename})
        self.Awards['Towel'] = outputlist

    def AggPoints(self):
        Aggpoints = PRCACAwards.config['AggregatePoints']
        outputlist = []
        filters = []
        for evt, Distances in Aggpoints['Events'].items():
            evtlist = [f"{evt}{dist}" for dist in Distances]
            for evt in evtlist:
                filters.append(evt)
        for swmr, strokes in self.data.items():
            agelist = []
            events = [stroke for stroke in strokes.keys() if stroke in filters]
            swmrpoints = 0
            for evt in events:
                evtpoints = sum(i['Points'] for i in self.data[swmr][evt] if i['Points'] != None)
                swmrpoints += evtpoints
                agelist.append(max([i['Age'] for i in self.data[swmr][evt] if isinstance(i['Age'],int)]))
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
        self.Trophies['AggPoints'] = sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

    def Improvement25(self):
        from datetime import timedelta
        improve25 = PRCACAwards.config['25Improvement']
        meetdates = []
        for v in self.data.values():
            for i in v.values():
                meetdates = meetdates + [x['Date'] for x in i]
        meets = sorted(set(meetdates))
        for Strokename in improve25['ProgressTimes'].keys():
            outputlist = []
            promotetimespan = timedelta(seconds=(PRCACAwards.ToSeconds(improve25['ProgressTimes'][Strokename])))
            for swmr, strokes in self.data.items():
                if f"{Strokename}25" in strokes.keys():
                    obj = {
                        'Swimmer': swmr,
                    }
                    fastest25span = None
                    first25span = None
                    for meet in meets:
                        meet25 = [m for m in self.data[swmr][f"{Strokename}25"] if m['Date'] == meet]
                        if meet25 != []:
                            try:
                                meet25span = timedelta(seconds=(PRCACAwards.ToSeconds(meet25[0]['Time'])))
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
                        events50 = self.data[swmr][f"{Strokename}50"]
                        swmr50 = True
                    except KeyError:
                        swmr50 = False
                    if fastest25span < promotetimespan and swmr50:
                        fastest50 = None
                        for meet in events50:
                            try:
                                meet50span = timedelta(seconds=(PRCACAwards.ToSeconds(meet['Time'])))
                            except:
                                continue
                            if not fastest50:
                                fastest50span = meet50span
                                fastest50date = meet['Date']
                            elif meet50span < fastest50span:
                                fastest50span = meet50span
                                fastest50date = meet['Date']
                        halved50 = fastest50span / 2
                        if halved50 < fastest25span:
                            str25of50 = str(halved50.total_seconds())
                            obj[fastest50date] = f"{str25of50} (50m)"
                            fastestspan = halved50
                            fastesttimestr = str25of50
                            fastestmeetdate = fastest50date
                    improvement = float((fastestspan - first25span).total_seconds())
                    obj['FirstTime'] = first25Time
                    obj['FastestTime'] = fastesttimestr
                    obj['FastestMeetDate'] = fastestmeetdate
                    obj['TimeImprovement'] = improvement
                    outputlist.append(obj)
            self.Trophies[f'{Strokename}25'] = (sorted(outputlist, key = lambda x: x['TimeImprovement']))

    def IM(self):
        im = PRCACAwards.config['IM']
        events = [f"IM{d}" for d in im['Distances']]
        outputlist = []
        for swmr in self.data.keys():
            strokes = [i for i in self.data[swmr].keys() if i in events]
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
                        strokepoints = sum([e['Points'] for e in self.data[swmr][evt] if isinstance(e['Points'],int)])
                        strokeage = max([e['Age'] for e in self.data[swmr][evt] if isinstance(e['Age'],int)])
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
        self.Trophies['IM'] = sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

    def Pinetathlon(self):
        from datetime import timedelta
        pinetathlon = PRCACAwards.config['Pinetathlon']
        outputlist = []
        allevents = []
        for i in pinetathlon['Events'].values():
            allevents.extend(i)
        pinestrokes = set(allevents)
        for swmr, strokes in self.data.items():
            ages = []
            for stroke in strokes.values():
                ages.append(max([m['Age'] for m in stroke if isinstance(m['Age'], int)]))
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
                        stroketimes.extend([timedelta(seconds=(PRCACAwards.ToSeconds(m['Time']))) for m in self.data[swmr][stroke] if m['Time'] != 'DQ'])
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
            cattimes = sorted(set([timedelta(seconds=(PRCACAwards.ToSeconds(i['TotalTime']))) for i in CatSwmrs]))
            for i in cattimes:
                placegetters = [c for c in CatSwmrs if timedelta(seconds=(PRCACAwards.ToSeconds(c['TotalTime']))) == i]
                for p in placegetters:
                    p['CategoryPlacing'] = placing
                placing += len(placegetters)
        self.Trophies['Pinetathlon'] = sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

    def Distance(self):
        distance = PRCACAwards.config['Distance']
        outputlist = []
        allevents = []
        for i in distance['Events'].values():
            if isinstance(i, str):
                allevents.append(i)
            elif isinstance(i, list):
                allevents.extend(i)
        diststrokes = set(allevents)
        for swmr, strokes in self.data.items():
            ages = []
            for stroke in strokes.values():
                ages.append(max([m['Age'] for m in stroke if isinstance(m['Age'], int)]))
            swmrage = max(ages)
            rangename = [k for k, v in distance['AgeRanges'].items() if swmrage in v][0]
            swmrdiststrokes = [s for s in strokes.keys() if s in distance['Events'][rangename]]
            if swmrdiststrokes != []:
                finalpoints = 0
                obj = {
                    'Swimmer': swmr,
                    'Age': swmrage,
                    'Category': rangename,
                    'CategoryPlacing': None
                }
                for ds in diststrokes:
                    if ds in strokes.keys() and ds in distance['Events'][rangename]:
                        strokepoints = sum([s['Points'] for s in self.data[swmr][ds] if isinstance(s['Points'], int)])
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
        self.Trophies['Distance'] = sorted(outputlist, key = lambda x: (x['Category'], x['CategoryPlacing']))

    def Endurance(self):
        endurance = PRCACAwards.config['Endurance']
        outputlist = []
        for swmr, strokes in self.data.items():
            ages = []
            for stroke in strokes.values():
                ages.append(max([m['Age'] for m in stroke if isinstance(m['Age'], int)]))
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
                        evtpoints = sum([e['Points'] for e in self.data[swmr][evt] if isinstance(e['Points'], int)])
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
        self.Trophies['Endurance'] = sorted(outputlist, key = lambda x: x['Placing'])
    
    def ClubChampion(self):
        outputlist = []
        for swmr, strokes in self.data.items():
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
        self.Trophies['ClubChampion'] = sorted(outputlist, key = lambda x: x['Placing'])
    
    def UpdateAwardsList(self):
        from csv import DictReader
        from pathlib import Path
        csvdata = []
        csvpath = f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\AwardsList.csv'
        pathtest = Path(csvpath).exists()
        if pathtest:
            with open(csvpath) as csvfile:
                for line in DictReader(csvfile):
                    csvdata.append(line)
        for k, newData in self.Awards.items():
            for nd in newData:
                try:
                    obj = [r for r in csvdata if r['Swimmer'] == nd['Swimmer']][0]
                except:
                    obj = {
                        'Swimmer': nd['Swimmer'],
                        'AchievementAwards': '',
                        'TowelAwards': ''
                    }
                    csvdata.append(obj)
                #Achievement Awards
                if k == 'Achievement':
                    if obj['AchievementAwards'] != '':
                        obj['AchievementAwards'] += f", {nd['AchievementAwards']}"
                    else:
                        obj['AchievementAwards'] = nd['AchievementAwards']
                #Towel Awards
                elif k == 'Towel':
                    obj['TowelAwards'] = nd['Stroke']
        self.AwardsList = csvdata
    
    def SwimmersEvents(self, Swimmer):
        outputlist = []
        for evt, meets in self.data[Swimmer].items():
            for meet in meets:
                obj = {
                    'Swimmer': Swimmer,
                    'Event': evt,
                    'Date': meet['Date'],
                    'Age': meet['Age'],
                    'pb': meet['pb'],
                    'Time': meet['Time'],
                    'seedTime': meet['seedTime'],
                    'Points': meet['Points'],
                    'Changed': meet['Changed']
                }
                outputlist.append(obj)
        try:
            self.swimmers[Swimmer] = sorted(outputlist, key = lambda x: (x['Event'], x['Date']))
        except:
            self.swimmers = {}
            self.swimmers[Swimmer] = sorted(outputlist, key = lambda x: (x['Event'], x['Date']))
        for line in self.swimmers[Swimmer]:
            print(line)
    
    def ExcelData(self, Swimmer):
        swimmername = f'Swenson, {Swimmer}'
        outputlist = []
        meetlist = []
        for meets in self.data[swimmername].values():
           meetlist.extend([i['Date'] for i in meets])
        meetdates = sorted(set(meetlist))
        for md in meetdates:
            obj = {'Date': md}   
            for evt, meets in self.data[swimmername].items():
                obj[evt] = None
                meetdata = [meet for meet in meets if meet['Date'] == md]
                if meetdata != []:
                    obj[evt] = meetdata[0]['Time']
            outputlist.append(obj)
        try:
            self.Swensons[Swimmer] = outputlist
        except:
            self.Swensons = {}
            self.Swensons[Swimmer] = outputlist

    def WriteAwardCsv(self):
        from csv import DictWriter
        from datetime import datetime
        from pathlib import Path
        from shutil import move
        today = datetime.now().strftime("%y%m%d")
        try:
            awards = self.AwardsList
        except:
            awards = False
        try:
            trophies = self.Trophies.keys()
        except:
            trophies = False
        writelist = []
        if awards:
            obj = {
                'awarddata': self.AwardsList,
                'csvpath': f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\AwardsList.csv',
                'backuploc': f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\_HistoricalAwardsLists\\AwardsList_{today}.csv'
            }
            writelist.append(obj)
        if trophies:
            for trophy in trophies:
                obj = {
                    'awarddata': self.Trophies[trophy],
                    'csvpath': f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\Trophies\\{trophy}.csv',
                    'backuploc': f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\Trophies\\{trophy}_{today}.csv'
                }
                writelist.append(obj)
        for i in writelist:
            filetest = Path(i['csvpath']).exists()
            backuptest = Path(i['backuploc']).exists()
            if filetest and backuptest:
                Path(i['csvpath']).unlink()
            elif filetest:
                move(i['csvpath'], i['backuploc'])
            with open(i['csvpath'], 'w', newline='') as csvfile:
                fieldnames = [k for k in i['awarddata'][0].keys()]
                writer = DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for obj in i['awarddata']:
                    writer.writerow(obj)

    def WriteAwardList(self):
        from datetime import datetime
        for award, swimmers in self.Awards.items():
            data = ''
            if award == 'Achievement':
                swimdate = max([i['Date'] for i in self.Awards[award]])
                listpath = f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\AchievementAwards\\Achievement_{swimdate}.txt'
                for s in swimmers:
                    data += f"\n{s['Swimmer']}\t-\t{s['AchievementAwards']}"
            elif award == 'Towel':
                stroke = self.Awards['Towel'][0]['Stroke']
                listpath = f'{self.SwimClubPath}\\{self.Season}\\ClubAwards\\TowelAwards\\{stroke}.txt'
                for s in swimmers:
                    data += f"\n{s['AgeGroup']}\t-\t{s['Swimmer']}\t-\t{s['Points']}"
            with open(listpath, 'w') as file:
                file.write(data)
    
    def WriteSwensonCsv(self):
        from csv import DictWriter
        from pathlib import Path
        for k in self.Swensons.keys():
            obj = {
                'awarddata': self.Swensons[k],
                'csvpath': f'C:\\Temp\\{k}.csv',
            }
            writelist.append(obj)
        for i in writelist:
            filetest = Path(i['csvpath']).exists()
            if filetest:
                Path(i['csvpath']).unlink()
            with open(i['csvpath'], 'w', newline='') as csvfile:
                fieldnames = [k for k in i['awarddata'][0].keys()]
                writer = DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                for obj in i['awarddata']:
                    writer.writerow(obj)