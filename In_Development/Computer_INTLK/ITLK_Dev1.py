#!/usr/bin/python
# -*- coding: utf-8 -*-

# '''
# RFID Terminal Computer Interlock

# In this code example, we create a
# custom dialog.

# author: Brian O'Connell
# last modified: June 2016
# '''

# Import the GUI toolkit module
try:
    import wx
except ImportError:
    raise ImportError,"The wxPython module is required to run this program."

import psycopg2
import psycopg2.extras
import sys, glob, serial, time, os
# curl utils
import pycurl
import ast
from io import BytesIO

# Initial Values

lid = 0
sid = 0
LName= " "
SName = " "
# port = ''
ser = None
user = False
access = None
RFID = 'RFID:'
# StartUse = 
X = None
Y = None

def serial_ports():
    # Lists serial port names for selection later

    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif sys.platform.startswith('darwin'):
        ports = glob.glob('/dev/tty.*')
    else:
        raise EnvironmentError('Unsupported platform')

    result = []
    for port in ports:
        try:
            s = serial.Serial(port)
            s.close()
            result.append(port)
        except (OSError, serial.SerialException):
            pass
    return result


# def Locations():
#     # Get list of locations and location ids
#     con = None

#     try:
#         con = psycopg2.connect(database='JMN', user='jadmin', password = 'jadmin_pw7', host = '130.64.17.0', port = '5432')
#         cur = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
#         # cur = con.cursor()
#         cur.execute('SELECT lid, name FROM locations WHERE lid > 0')
#         locations = cur.fetchall()
#         # print locations
#         # for row in locations:
#         #     print "%s %s" % (row["lid"], row["name"])
#     except psycopg2.DatabaseError, e:
#         print 'Error %s' % e
#         sys.exit(1)
#     finally:
#         if con:
#             con.close()

#     # locations = [[0, 'Nowhere'],[1, 'Jumbo\'s Maker Studio'],[5, 'Bray Machine Shop']]

#     return locations


# def Stations(loc):
#     # Acquires a list of stations listed in the database and their ids
#     # loc = 1

#     if loc == 0:
#         stations = [[0, " none available "]]
#     else:
#         con = None

#         try:
#             con = psycopg2.connect(database='JMN', user='jadmin', password = 'jadmin_pw7', host = '130.64.17.0', port = '5432')
#             cur = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
#             # cur = con.cursor()
#             cur.execute('SELECT sid, name FROM stations WHERE loc = ' + str(loc))
#             stations = cur.fetchall()
#             # for row in stations:
#             #   print "%s %s" % (row["sid"], row["name"])
#         except psycopg2.DatabaseError, e:
#             print 'Error %s' % e
#             sys.exit(1)
#         finally:
#             if con:
#                 con.close()

#     # stations = [[16, 'Sign In Station'], [13, 'Green Status'], [14, 'Yellow Status'], [15, 'Red Status']]

#     return stations

def Locations():
    buffer = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.URL, 'http://130.64.17.0:8000/RFID/locations/')
    c.setopt(c.WRITEDATA, buffer)
    c.perform()
    c.close()

    body = buffer.getvalue()
    l_dict = ast.literal_eval(body)

    return l_dict


def Stations(loc):
    # Acquires a list of stations listed in the database and their ids
    # loc = 1

    if loc == 0:
        stations = {0: " none available "}
    else:
        buffer = BytesIO()
        stations_url = 'http://130.64.17.0:8000/RFID/locations/' + str(loc) + '/'
        c = pycurl.Curl()
        c.setopt(c.URL, stations_url)
        c.setopt(c.WRITEDATA, buffer)
        c.perform()
        c.close()

        body = buffer.getvalue()
        stations = ast.literal_eval(body)

    return(stations)

def GetUID(rfid):
    print "Getting UID"
    con = None
    try:
        con = psycopg2.connect(database='JMN', user='jadmin', password = 'jadmin_pw7', host = '130.64.17.0', port = '5432')
        cur = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
        # cur = con.cursor()
        cur.execute("SELECT uid, fname FROM users WHERE rfid = \'E\\\\x" + rfid + "\'")

        userInfo = cur.fetchall()
        print userInfo
        # for row in stations:
        #   print "%s %s" % (row["sid"], row["name"])
    except psycopg2.DatabaseError, e:
        print 'Error %s' % e
        sys.exit(1)
    finally:
        if con:
            con.close()

    if not userInfo:
        userInfo = [[0, 'No User']]
    return (userInfo[0][0], userInfo[0][1]) #(userInfo["uid"], userInfo["fname"])

def CheckAccess(uid):
    print "Checking for Access"
    global sid

    con = None
    try:
        con = psycopg2.connect(database='JMN', user='jadmin', password = 'jadmin_pw7', host = '130.64.17.0', port = '5432')
        cur = con.cursor(cursor_factory=psycopg2.extras.DictCursor)
        # cur = con.cursor()
        cur.execute('SELECT access FROM permissions WHERE uid = ' + str(uid) + ' AND sid = ' + str(sid))
        response = cur.fetchall()
        print response
        access = response[0][0]
        if response[0][0] == True:
            access = True
        elif response[0][0] == False:
            access = False
        else:
            access = None

        print access
        # for row in stations:
        #   print "%s %s" % (row["sid"], row["name"])
    except psycopg2.DatabaseError, e:
        print 'Error %s' % e
        sys.exit(1)
    finally:
        if con:
            con.close()
    return access

def GetData():
    global ser
    # Check the serial port for the arduino serial
    ser.flushInput() # Flush the serial port
    time.sleep(.75) # Wait for the next signal
    key = 'RFID:'   # A known key from the arduino feed
    data = ser.readline()[:-2]
    for i in range(0,6): # Check the port 1 to 5 times
        if data[0:5] == key:    # Check and make sure the information meets the key
            break
        else:   # If it doesn't, try again
            ser.flushInput()
            time.sleep(.75)
            data = ser.readline()[:-2]
            print 'missed key on User Check - ' + str(i)
    if data[0:5] != key:
        data = ''
    return data

# Set up a configuration file to assist in restarting the application when closed. 
class ConfigWindow(wx.Dialog):
  
    def __init__(self, parent, title):
        super(ConfigWindow, self).__init__(parent, title=title, size=(500, 500))

        global lid, sid #, LName, SName

        self.cfg = wx.Config('station_configuration')
        # self.cfg.DeleteAll()

        if self.cfg.Exists('Location'):
            lid, sid = self.cfg.ReadInt('Location'), self.cfg.ReadInt('Station')
            # LName, SName = self.cfg.ReadInt('LocName'), self.cfg.ReadInt('StaName')
            print lid
            print sid
            # print LName
            # print SName
        
        self.InitUI()
        # self.SetSize(500,500)
        self.SetTitle("Configurate Computer Interlock")
        self.SetWindowStyle(wx.STAY_ON_TOP & ~wx.RESIZE_BORDER)
        self.Centre()
        self.Show()     
        
    def InitUI(self):
        print "initializing the configuration window"
        global lid, sid, LName, SName

        panel = wx.Panel(self)
        self.SetBackgroundColour('#418FDE')

        font = wx.SystemSettings_GetFont(wx.SYS_SYSTEM_FONT)
        font.SetPointSize(9)

        #Establish the timer (For use when checking serial ports)
        print 'Established Config timer'
        self.ConfigTimer = ConfigTimer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self.ReadPort, id=self.ConfigTimer.GetId())

        #Locations info
        print 'creat Locations info'
        ltl = wx.StaticText(panel, label=' Locations ')
        print 'Created ltl'
        locs = Locations()
        locs = zip(*locs)
        if lid:
            LName = locs[1][locs[0].index(lid)]
        else:
            LName = " "
        self.lb = lb = wx.ComboBox(panel, value=LName, choices=locs[1], style=wx.CB_READONLY)
        lb.Bind(wx.EVT_COMBOBOX, self.LocSelect, id=lb.GetId())

        #Stations info
        print 'Create Stations info'
        stl = wx.StaticText(panel, label=' Stations ')
        stns = Stations(lid)
        stns1 = zip(*stns)
        if sid:
            SName = stns1[1][stns1[0].index(sid)]
        else:
            SName = " "
        self.sb = sb = wx.ComboBox(panel, -1, value=SName, choices=stns1[1], style=wx.CB_READONLY)
        sb.Bind(wx.EVT_COMBOBOX, self.StaSelect, id=sb.GetId())

        # Set up Vertical box
        vbox = wx.BoxSizer(wx.VERTICAL)

        # Set up locations box
        hbox1 = wx.BoxSizer(wx.HORIZONTAL)
        hbox1.Add(ltl, 1 , flag=wx.RIGHT, border=8)
        hbox1.Add(lb, 1 , flag=wx.RIGHT, border=8)
        vbox.Add(hbox1, flag=wx.EXPAND|wx.LEFT|wx.RIGHT|wx.TOP, border=10)
        vbox.Add((-1, 10))

        #Set up Stations box
        hbox2 = wx.BoxSizer(wx.HORIZONTAL)
        hbox2.Add(stl, 1 , flag=wx.RIGHT, border=8)
        hbox2.Add(sb, 1 , flag=wx.RIGHT, border=8)
        vbox.Add(hbox2, flag=wx.EXPAND|wx.LEFT|wx.RIGHT|wx.TOP, border=10)
        vbox.Add((-1, 10))


        #Serial Ports Info
        pt = wx.StaticText(panel, label=' Available Serial Ports ')
        pl = serial_ports()
        self.pb = pb = wx.ComboBox(panel, -1, value=" ", choices=pl, style=wx.CB_READONLY)
        pb.Bind(wx.EVT_COMBOBOX, self.PortSelect, id=pb.GetId())


        # Set up Serial Ports Box
        hbox3 = wx.BoxSizer(wx.HORIZONTAL)
        hbox3.Add(pt, 1 , flag=wx.RIGHT, border=8)
        hbox3.Add(pb, 1 , flag=wx.RIGHT, border=8)
        vbox.Add(hbox3, flag=wx.EXPAND|wx.LEFT|wx.RIGHT|wx.TOP, border=10)
        vbox.Add((-1, 10))


        hbox4 = wx.BoxSizer(wx.HORIZONTAL)

        st1 = wx.StaticText(panel, label='Reading ports...')
        hbox4.Add(st1, 1 , flag=wx.RIGHT, border=8)
        self.tc = tc = wx.StaticText(panel, label='....')
        hbox4.Add(tc, proportion=1, border=10)
        vbox.Add(hbox4, flag=wx.EXPAND|wx.LEFT|wx.RIGHT|wx.TOP, border=10)
        vbox.Add((-1, 10))

        hbox5 = wx.BoxSizer(wx.HORIZONTAL)
        btn1 = wx.Button(panel, label='Save', size=(70, 30))
        hbox5.Add(btn1)
        self.btn2 = btn2 = wx.Button(panel, label='Close', size=(70, 30))
        hbox5.Add(btn2, flag=wx.LEFT|wx.BOTTOM, border=5)
        vbox.Add(hbox5, flag=wx.ALIGN_RIGHT|wx.RIGHT, border=10)

        btn1.Bind(wx.EVT_BUTTON, self.OnSave)
        btn2.Bind(wx.EVT_BUTTON, self.Cancel)
        self.btn2.Enable(False)

        panel.SetSizer(vbox)

    def OnSave(self, event):
        global lid, sid #, LName, SName
        self.cfg.DeleteAll()
        self.cfg.WriteInt("Location", lid)
        self.cfg.WriteInt("Station", sid)
        # self.cfg.Write("LocName", LName)
        # self.cfg.Write("StaName", SName)
        print 'Saving configuration'
        # self.cfg.Write("SerialPort", port)
        # self.statusbar.SetStatusText('Configuration saved, %s ' % wx.Now())

    def Cancel(self, event):
        self.ConfigTimer.Stop()
        self.Close()

    def LocSelect(self, event):
        global lid, LName
        item = event.GetSelection()
        LName = event.GetString()
        locs = Locations()
        locs = zip(*locs)
        lid = locs[0][item]
        # LName = locs[1][item]

        stns = Stations(lid)
        stns1 = zip(*stns)
        self.sb.Clear()
        self.sb.SetItems(stns1[1])
        print 'Location selected'

    def StaSelect(self, event):
        global lid, sid, SName
        item = event.GetSelection()
        SName = event.GetString()
        stns = Stations(lid)
        stns = zip(*stns)
        sid = stns[0][item]
        # SName = stns[1][item]
        print 'Station selected'

    def PortSelect(self, event):
        global ser
        print 'Port selected'
        port = event.GetString()
        print 'starting timer'
        ser = serial.Serial(port, 9600) #, timeout=.1)
        self.ConfigTimer.Start(5000)

    def ReadPort(self,event):
        data = GetData()
        if data:
            self.btn2.Enable(True)
            self.tc.SetLabel(data)
        else:   # Flush and reread the serial port
            self.btn2.Enable(False)
            self.tc.SetLabel('Improper data format')
        
class Interlock(wx.Frame):
    
    def __init__(self, parent):
        global sid
        super(Interlock, self).__init__(parent, title='Computer Interlock', style = wx.STAY_ON_TOP | wx.CAPTION | wx.MAXIMIZE | wx.RESIZE_BORDER) 
        # super(Interlock, self).__init__(parent, title='Computer Interlock', style = wx.CAPTION | wx.MAXIMIZE | wx.RESIZE_BORDER)
        print "Initializing the display."
        self.InitDisplay()
        print "Initializing the interactions."
        self.InitUI()
        print 'Initial Configuring...'
        self.SetWindowStyle(~wx.STAY_ON_TOP)
        CFig = ConfigWindow(self, title='Configure Computer Interlock')
        CFig.ShowModal()
        CFig.Destroy()
        self.SetWindowStyle(wx.STAY_ON_TOP)
        self.SetFocus()
        self.MainTimer.Start(2500)

    def InitDisplay(self):
        global X, Y
        displaySize= wx.DisplaySize()
        print displaySize
        X = displaySize[0]
        Y = displaySize[1]
        W = X * 0.9
        H = Y * 0.9
        self.SetSize((W,H))

        self.SetBackgroundColour('#c6bfb6')
        self.Centre()

        # Set up Vertical box
        # self.MBox = 
        self.MBox = Mbox= wx.BoxSizer(wx.VERTICAL)

        #Create Content
        self.WTxt = WTxt = wx.StaticText(self, label=" Initial Configuration... ", style=wx.ALIGN_CENTER) 
        self.ATxt = ATxt = wx.StaticText(self, label=" Still Configuring...", style=wx.ALIGN_CENTER)
        font = wx.Font(36, wx.DECORATIVE, wx.ITALIC, wx.BOLD)
        self.WTxt.SetFont(font)
        self.ATxt.SetFont(font)
        logo = wx.StaticBitmap(self, bitmap=wx.Bitmap('JMN_LOGO.png'))

        #Add content to vertical box
        Mbox.Add((-1, H * .1))
        Mbox.Add(WTxt, 1, flag=wx.ALIGN_CENTER, border=10) 
        Mbox.Add(logo, 1, wx.ALIGN_CENTER_HORIZONTAL, 25)
        Mbox.Add(ATxt, 1, flag=wx.ALIGN_CENTER, border=10) 
        Mbox.Add((-1, H * .1))

        self.SetSizer(Mbox)

        self.SetMinSize(self.GetSize())
        self.SetMaxSize(self.GetSize())

        self.Show(True)
     
    def InitUI(self):  
        # Hidden Control Commands
        cfig_id = wx.NewId()
        cls_id = wx.NewId()
        ul_id = wx.NewId()
        l_id = wx.NewId()
        self.Bind(wx.EVT_MENU, self.Config, id=cfig_id)
        self.Bind(wx.EVT_MENU, self.OnQuit, id=cls_id)
        self.Bind(wx.EVT_MENU, self.EUnLock, id=ul_id)
        self.Bind(wx.EVT_MENU, self.ELock, id=l_id)

        self.accel_tbl = wx.AcceleratorTable([(wx.ACCEL_SHIFT|wx.ACCEL_ALT, ord('J'), cfig_id),
                                              (wx.ACCEL_SHIFT|wx.ACCEL_ALT, ord('T'), cls_id),
                                              (wx.ACCEL_SHIFT|wx.ACCEL_ALT, ord('U'), ul_id),
                                              (wx.ACCEL_SHIFT|wx.ACCEL_ALT, ord('L'), l_id)
                                             ]) 
        self.SetAcceleratorTable(self.accel_tbl)

        # Setup timer for checking the Serial com
        self.MainTimer = MainTimer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self.UserCheck, id=MainTimer.GetId())

        #setup user timer (For use when checking serial ports)
        self.UserTimer = UserTimer = wx.StopWatch()
        # self.Bind(wx.EVT_TIMER, self.ReadPort, id=self.ConfigTimer.GetId())

        # React to being moved
        # self.Bind(wx.EVT_MOVE, self.Lock)
        
    def Config(self, event):
        print 'Configuring...'
        self.MainTimer.Stop()
        self.SetWindowStyle(~wx.STAY_ON_TOP)
        CFig = ConfigWindow(None, title='Configure Computer Interlock')
        CFig.ShowModal()
        CFig.Destroy()
        self.SetWindowStyle(wx.STAY_ON_TOP)
        self.SetFocus()
        self.MainTimer.Start(2500)

    def OnQuit(self, event):
        print 'quiting...'
        self.MainTimer.Stop()
        self.Close()


    def ILock(self, status, WText, AText): #Either locks or unlocks the window
        global X, Y
        print ''
        # self.Freeze()
        self.SetFocus()
        self.WTxt.SetLabel(WText)
        self.ATxt.SetLabel(AText)
        self.MBox.Layout()
        # self.Freeze()
        if status:        
            # self.SetTransparent(100)
            print ' Unlocking the screen '
            time.sleep(3)
            self.Freeze()
            self.SetWindowStyle(~wx.STAY_ON_TOP)
            dX = X * .75
            dY = Y * .75
            # self.MoveXY(dX,dY)
            self.MoveXY(X,Y)
            self.Thaw()
        elif not status:
            print ' Locking the screen '
            self.Freeze()
            self.Centre()
            # self.Raise()
            # self.SetTransparent(200)
            self.SetWindowStyle(wx.STAY_ON_TOP)
            # dX = X * 0.05
            # dY = Y * 0.05
            # self.MoveXY(dX,dY)
            self.Thaw()
        # self.Thaw()

    def UserCheck(self,event):
        global ser, RFID, user, access, LName, SName

        print 'begin of user check '

        if not user:
            print 'No current user'
            # Check the serial port for an RFID
            self.SetFocus()
            data = GetData()
            print 'UserCheck: ' + data

            if data[5] != '#':  # Then there is still no user
                print 'No new RFID '
                self.ILock(False, (" Welcome to " + LName) , (" The " + SName + "Station") # Reset the lock 
                user = False    # Reaffirm no user in place
            elif data[5] == '#': 
                user = True                 # There's a user now
                self.UserTimer.Start()      # Start the usage timer
                rfid = data[6:14]           # Grab the RFID hex string
                RFID = rfid                 # Keep global copy of the RFID
                uid, fname = GetUID(rfid)   # Check for uid and username

                if uid == 0:    # No user in database
                    self.ILock(False, " No user in database ", " Please check with Administrator ")  # refresh the computer lock
                    access = None
                    return
                elif uid >0:    # Valid user in the database            
                    access = CheckAccess(uid)   # Check the access status of the RFID
                    # Lock or unlock based on access
                    if access:
                        WText = "Welcome " + fname
                        AText = " Access granted "
                        self.ILock(True, WText, AText)
                    elif access is None:
                        WText = "Welcome " + fname
                        AText = "No Permission Status in System. Contact Admin."
                        self.ILock(False, WText, AText)
                    elif access is False:
                        WText = "Welcome " + fname
                        AText = "Further Training Required. Contact Admin."
                        self.ILock(False, WText, AText)
                    else:
                        WText = "Welcome " + fname
                        AText = "Some Error Occured."
                        self.ILock(False, WText, AText)

        elif user:
            print 'A user is logged'
            print 'begin of user check '
            self.SetFocus()
            data = GetData()
            print 'UserCheck: ' + data
            rfid = data[6:14]           # Grab the RFID hex string
            uid, fname = GetUID(rfid)   # Check for uid and username

            if rfid == RFID:
                # If there's no change in users, reaffirm locked statuses
                if access is None:
                    WText = "Welcome " + fname
                    AText = "No Permission Status in System. Contact Admin."
                    self.ILock(False, WText, AText)
                elif access is False:
                    WText = "Welcome " + fname
                    AText = "Further Training Required. Contact Admin."
                    self.ILock(False, WText, AText)
            else:
                # If there's been a change then relock the system and change user status
                user = False
                # Record the time of use
                msec = self.UserTimer.Time()
                self.UserTimer.Pause()
                sec = int(msec)/1000
                print 'Use Time: ' + str(sec) + ' sec'
                self.ILock(False, (" Welcome to " + LName) , (" The " + SName + "Station")



    def EUnLock(self, event):
        global X, Y
        print 'unlocking manually'
        WText = " Manually Unlocked "
        AText = " Manually Unlocked "
        self.ILock(True, " WText ", " AText ")
        # n = self.GetId()
        # print 'self Id - ' + str(n)
        # self.SetFocus()
        # self.WTxt.SetLabel(' Unlocked ')
        # self.ATxt.SetLabel(' Unlocked ')
        # # self.Lower()
        # self.SetTransparent(127)
        # # self.SetWindowStyle(~wx.STAY_ON_TOP)
        # # dX = X * .5
        # # dY = Y * .5
        # # self.MoveXY(dX,dY)
        # # time.sleep(5)

    def ELock(self, event):
        global X, Y
        print 'locking manually'
        WText = " Manually locked "
        AText = " Manually locked "
        self.ILock(True, " WText ", " AText ")
        # n = self.GetId()
        # print 'self Id - ' + str(n)
        # self.SetFocus()
        # self.WTxt.SetLabel(' Locked ')
        # self.ATxt.SetLabel(' Locked ')
        # self.Centre()
        # # self.Raise()
        # self.SetTransparent(255)
        # # self.SetWindowStyle(wx.STAY_ON_TOP)
        # # dX = X * 0.05
        # # dY = Y * 0.05
        # # self.MoveXY(X,Y)



   
def main():
    
    ex = wx.App()
    Interlock(None)
    ex.MainLoop()
   

if __name__ == '__main__':
    main()

