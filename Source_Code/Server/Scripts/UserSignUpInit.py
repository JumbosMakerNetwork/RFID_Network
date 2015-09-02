#!/usr/bin/python
# -*- coding: utf-8 -*-

import psycopg2
import sys


con = None

try:
     
    con = psycopg2.connect("dbname='JMN_DEV' user='jadmin' password='jadmin_pw7'") 

    username = sys.argv[1]
    cur = con.cursor()    
    cur.execute("SELECT uid FROM users WHERE uname=%s", username)
    uid = cur.fetchone()

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