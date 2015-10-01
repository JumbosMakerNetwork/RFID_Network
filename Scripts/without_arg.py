#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

import psycopg2
import sys


con = None

try:
     
    con = psycopg2.connect("dbname='JMN_DEV' user='Testuser'") 
    
    cur = con.cursor()    
    cur.execute("SELECT * FROM users")
    userlist = cur.fetchall()

    numUsers = 0;
    for user in userlist:
        numUsers++

    uid = numUsers

    cur = con.cursor()    
    cur.execute("SELECT * FROM stations")
    stations = cur.fetchall()

    sid = 1;
    # for each station, 
    for station in stations:
    	cur.execute("INSERT INTO permissions (sid, uid, access) VALUES ("+sid+", "+uid+", FALSE)")
        sid++
    

except psycopg2.DatabaseError, e:
    print 'Error %s' % e    
    sys.exit(1)
    
    
finally:
    
    if con:
        con.close()