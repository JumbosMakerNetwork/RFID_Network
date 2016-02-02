#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

import psycopg2
import sys


con = None

try:
     
    con = psycopg2.connect("host='130.64.17.0' dbname='JMN' user='dolanwill' password='password7'") 
    cur = con.cursor()

    sid = 9
    uid = 19    
    exec_string = "SELECT * FROM permissions where uid = {0}".format(uid)
    cur.execute(exec_string)
    perms = cur.fetchall()
    for perm in perms:
        print perm[0]

    print "inserting now"
    exec_string = "INSERT INTO permissions (sid, uid, access) VALUES ({0}, {1}, FALSE)".format(sid, uid)
    cur.execute(exec_string)

    exec_string = "SELECT * FROM permissions where uid = {0}".format(uid)
    cur.execute(exec_string)
    perms = cur.fetchall()
    for perm in perms:
        print perm[0]

    con.commit()

except psycopg2.DatabaseError, e:
    print 'Error %s' % e    
    sys.exit(1)
    
    
finally:
    
    if con:
        con.close()