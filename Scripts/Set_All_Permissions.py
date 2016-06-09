#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

# This is the code for automatically assigning 'false' permission to each user
# when a new station gets added. One must "pass" the sid number into this function.

import psycopg2
import sys
import string


con = None

try:
    con = psycopg2.connect("host='130.64.17.0' dbname='JMN' user='xx' password='xx  '") 

    cur = con.cursor()    
    cur.execute("SELECT * FROM users")
    users = cur.fetchall()
    cur.execute("SELECT * FROM stations")
    stations = cur.fetchall()

    numAdded = 0;
    # for each user, 
    for user in users:
        # grab the uid, which is the data at index 0 for each item in the results array
        uid = user[0]
        for station in stations:
            # grab the sid, same method as uid
            sid = station[0]
            exec_string = "SELECT * FROM permissions WHERE sid = {0} AND uid = {1}".format(sid, uid)
            cur.execute(exec_string)
            result = cur.fetchall()
            if(result):
                pass
            else:
                exec_string = "INSERT INTO permissions (sid, uid, access) VALUES ({0}, {1}, FALSE)".format(sid, uid)
                cur.execute(exec_string)
                numAdded = numAdded + 1

    print "Number of permissions added = "
    print numAdded

    con.commit()

except psycopg2.DatabaseError, e:
    print 'Error %s' % e    
    sys.exit(1)
    
    
finally:
    
    if con:
        con.close()