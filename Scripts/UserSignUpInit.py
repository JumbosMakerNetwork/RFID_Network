#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*- 

# This is the code for automatically assigning 'false' permission for each station
# when a new user gets added. One must "pass" the uid number into this function.

import psycopg2
import sys


con = None

try:
     
    con = psycopg2.connect("dbname=JMN user='xx' password='xx'") 
    con.autocommit = True

    uid = sys.argv[1]
    
    cur = con.cursor()    
    cur.execute("SELECT * FROM stations")
    stations = cur.fetchall()

    # for each station, 
    for station in stations:
        # grab the sid, which is the first element of data in each item in the resutls array
        sid = station[0]
        cur.execute("INSERT INTO permissions (sid, uid, access) VALUES (%s, %s, FALSE)", (sid, uid))

except psycopg2.DatabaseError, e:
    if con:
        con.rollback()

    print 'Error %s' % e    
    sys.exit(1)
    
    
finally:
    
    if con:
        con.close()