#!/usr/bin/python
# -*- coding: utf-8 -*-

# '''
# RFID Terminal Computer Interlock

#cd /Users/boconn7782/Documents/GradSchool/Dissertation/MakerStudio_Equipment/GIT/In_Development/Computer_INTLK

# In this code example, we create a
# custom dialog.

# author: Brian O'Connell
# last modified: June 2016
# '''

#'''
# Program functions by sniffing a station status field in the database.
# Using the URL http://130.64.17.0:8000/RFID/inUse/<sid>/ 
# This returns {'access': 'False null.', 'uname': 'null', 'email': 'null@null.com', 'fname': 'null'} when not in use
# This returns {'access': 'True Will.', 'uname': 'dolanwill', 'email': 'dolanwill@gmail.com', 'fname': 'Will'} when in use by user "dolanwill"

#'''

# Import the GUI toolkit module
try:
    import wx
except ImportError:
    raise ImportError,"The wxPython module is required to run this program."

# import psycopg2
# import psycopg2.extras
import sys, glob, time, os, pycurl, ast

try:
    from io import BytesIO
except ImportError:
    raise ImportError,"The io module is required to run this program."

# if getattr(sys, 'frozen', False):
#     os.chdir(sys._MEIPASS)

# Initial Values

lid = 0
sid = 0
LName= " "
SName = " "
user = False
access = False
UName = 'None'
X = None
Y = None

def Locations():
    # Returns a dictionary of locations keyed to their ids from the database
    buffer = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.URL, 'http://130.64.17.0:8000/RFID/locations/')
    c.setopt(c.WRITEDATA, buffer)
    c.perform()
    c.close()

    body = buffer.getvalue()
    locations = ast.literal_eval(body)
    del locations[0] # Eliminates the arbitrary location 'Out'

    return locations


def Stations(loc):
    # Returns a dictionary of stations for that location keyed to their station ids from the database

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

    return stations

def CheckUser(station):
    # Returns a dictionary of the user associated with the ID at that location's terminal

    print "Checking for user at terminal..."
    buffer = BytesIO()
    c = pycurl.Curl()
    c.setopt(c.URL, 'http://130.64.17.0:8000/RFID/inUse/' + str(station) + '/')
    c.setopt(c.WRITEDATA, buffer)
    c.perform()
    c.close()

    body = buffer.getvalue()
    user_info = ast.literal_eval(body)

    return user_info



class ConfigWindow(wx.Dialog):
  
    def __init__(self, parent, title):
        super(ConfigWindow, self).__init__(parent, title=title, size=(500, 500))

        global lid, sid #, LName, SName

        # Set up a configuration file to assist in restarting the application when closed. 
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
        self.Bind(wx.EVT_TIMER, self.CheckConnection, id=self.ConfigTimer.GetId())
        if sid != 0:
            self.ConfigTimer.Start(2500)

        #Locations info
        print 'creat Locations info'
        ltl = wx.StaticText(panel, label=' Locations ')
        print 'Created ltl'
        locs = Locations()
        if lid:
            LName = locs[lid]
        else:
            LName = " "

        self.lb = lb = wx.ComboBox(panel, value=LName, choices=locs.values(), style=wx.CB_READONLY)
        lb.Bind(wx.EVT_COMBOBOX, self.LocSelect, id=lb.GetId())

        #Stations info
        print 'Create Stations info'
        stl = wx.StaticText(panel, label=' Stations ')
        stns = Stations(lid)
        if sid:
            SName = stns[sid]
        else:
            SName = " "

        self.sb = sb = wx.ComboBox(panel, -1, value=SName, choices=stns.values(), style=wx.CB_READONLY)
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

        # User Info 
        hbox4 = wx.BoxSizer(wx.HORIZONTAL)

        user1 = wx.StaticText(panel, label='User Name: ')
        hbox4.Add(user1, 1, flag = wx.RIGHT, border = 8)
        self.user2 = user2 = wx.StaticText(panel, label = ' Waiting for DB...')
        hbox4.Add(user2, proportion = 1, border = 10)
        vbox.Add(hbox4, flag=wx.EXPAND | wx.LEFT | wx.RIGHT | wx.TOP, border = 10)
        vbox.Add((-1,10))

        # Control buttons
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
        print LName
        locs = Locations()
        lid = locs.keys()[item]
        # locs = zip(*locs)
        # lid = locs[0][item]
        # LName = locs[1][item]

        stns = Stations(lid)
        # stns1 = zip(*stns)
        self.sb.Clear()
        self.sb.SetItems(stns.values())
        print 'Location selected'

    def StaSelect(self, event):
        global lid, sid, SName
        item = event.GetSelection()
        SName = event.GetString()
        print SName
        stns = Stations(lid)
        # stns = zip(*stns)
        sid = stns.keys()[item]
        # SName = stns[1][item]
        print 'Station selected'
        # self.CheckConnection()
        self.ConfigTimer.Start(2500)

    def CheckConnection(self, event):
        global sid
        print " Checking connection "

        CurrUser = CheckUser(sid)
        print type(CurrUser)
        print CurrUser
        if CurrUser['uname']:
            self.btn2.Enable(True)
            self.user2.SetLabel(CurrUser['uname'])
        else:
            self.btn2.Enable(False)
            self.tc.SetLabel('Improper data format')

 

class Interlock(wx.Frame):
    
    def __init__(self, parent):
        global sid
        super(Interlock, self).__init__(parent, title='Computer Interlock', style = wx.STAY_ON_TOP | wx.CAPTION ) 
        # super(Interlock, self).__init__(parent, title='Computer Interlock', style = wx.CAPTION | wx.MAXIMIZE | wx.RESIZE_BORDER)
        print "Initializing the display."
        self.InitDisplay()
        print "Initializing the interactions."
        self.InitUI()
        print 'Initial Configuring...'
        self.SetWindowStyle(~wx.STAY_ON_TOP)

        # if self.cfg.Exists('Location'):
        #     lid, sid = self.cfg.ReadInt('Location'), self.cfg.ReadInt('Station')
        #     # LName, SName = self.cfg.ReadInt('LocName'), self.cfg.ReadInt('StaName')
        #     print lidÔ
        #     print sid
        #     # print LName
        #     # print SName
        CFig = ConfigWindow(self, title='Configure Computer Interlock')
        CFig.ShowModal()
        CFig.Destroy()

        self.SetWindowStyle(wx.STAY_ON_TOP)
        self.SetFocus()
        self.MainTimer.Start(5000)

    def InitDisplay(self):
        global X, Y
        displaySize= wx.DisplaySize()
        print displaySize
        X = displaySize[0]
        Y = displaySize[1]
        W = X * 1.01
        H = Y * 1.01
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
        logo = wx.StaticBitmap(self, bitmap=wx.Bitmap("C:\Users\Brian O'Connell\Documents\RFID_Network\CPU_ITLK\JMN_LOGO.png"))

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
        self.MainTimer.Start(5000)

    def OnQuit(self, event):
        print 'quiting...'
        self.MainTimer.Stop()
        self.Close()


    def SetText(self, WText, AText):
        self.SetFocus()
        self.WTxt.SetLabel(WText)
        self.ATxt.SetLabel(AText)
        self.MBox.Layout()

    def ILock(self, status):
        global X, Y, access
        if status:        
            # self.SetTransparent(100)
            print ' Unlocking the screen '
            if not access:
                print 'Delaying once to view'
                self.MainTimer.Stop()
                # time.sleep(2)
                self.MainTimer.Start(2000)
            elif access:  
                self.Freeze()
                self.SetWindowStyle(~wx.STAY_ON_TOP)
                self.Iconize(True)
                self.Show(False)
                self.Thaw()
                if self.MainTimer.GetInterval() == 2000:
                    self.MainTimer.Start(5000)
        elif not status:
            print ' Locking the screen '
            self.Freeze()
            self.Iconize(False)
            self.Show(True)
            self.Centre()
            self.SetWindowStyle(wx.STAY_ON_TOP | wx.MAXIMIZE)
            self.Thaw()
            self.SetFocus()

    def UserCheck(self,event):
        global sid, UName, user, access, LName, SName

        # print ' user checking for user... '

        # Check for change in user
        UInfo = CheckUser(sid)
        # print 'UserCheck: ' + str(UInfo)
        self.SetFocus()

        # {'access': 'True', 'uname': 'dolanwill', 'email': 'dolanwill@gmail.com', 'fname': 'Will'}
        # {'access': 'False', 'uname': 'null', 'email': 'null@null.com', 'fname': 'null'}

        ACCESS = ast.literal_eval(UInfo['access']) 
        uname = UInfo['uname']
        FName = UInfo['fname']

        if not ACCESS and uname == 'null':
            print 'No new user'
            WText = " Welcome to " + LName
            AText = " Station: " + SName
            self.SetText(WText, AText)
            self.ILock(False) # Refresh the Lock
            access = False
        elif not ACCESS and uname != 'null':
            print 'User but insufficient credentials'
            WText = " Welcome " + FName
            AText = " Sorry, but more training necessary "
            self.SetText(WText, AText)
            self.ILock(False) # Refresh the Lock
            access = False
        elif ACCESS:
            print 'User and sufficient credentials'
            WText = " Welcome " + FName
            AText = " Enjoy Making today "
            self.SetText(WText, AText)
            self.ILock(True) # Refresh the Lock
            access = True


    def EUnLock(self, event):
        global access
        print 'unlocking manually'
        WText = " Manually Unlocking "
        AText = " Manually Unlocking "
        self.SetText(WText, AText)
        self.MainTimer.Stop()
        access = True
        self.ILock(True)

    def ELock(self, event):
        global access
        print 'locking manually'
        WText = " Manually locked "
        AText = " Manually locked "
        self.SetText(WText, AText)
        self.MainTimer.Start(2500)
        self.ILock(False)
        access = False



   
def main():
    
    ex = wx.App()
    Interlock(None)
    ex.MainLoop()
   

if __name__ == '__main__':
    main()

