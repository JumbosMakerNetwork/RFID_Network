#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

# This is the code for automatically assigning 'false' permission to each user
# when a new station gets added. One must "pass" the sid number into this function.

import psycopg2
import sys


con = None

try:
     
    con = psycopg2.connect("dbname=JMN user='xxx' password='xxx'") 

    sid = sys.argv[1]

    cur = con.cursor()    
    cur.execute("SELECT * FROM users")
    users = cur.fetchall()

    # for each user, 
    for user in users:
        # grab the uid, which is the data at index 0 for each item in the results array
        uid = user[0]
    	cur.execute("INSERT INTO permissions (sid, uid, access) VALUES ("+sid+", "+uid+", FALSE)")
    

except psycopg2.DatabaseError, e:
    print 'Error %s' % e    
    sys.exit(1)
    
    
finally:
    
    if con:
        con.close()