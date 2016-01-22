#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

import time
import psycopg2
import sys


con = None

try:
    con_string = "host='130.64.17.0' dbname='JMN' user='jadmin' password='jadmin_pw7'"
 
    # print the connection string we will use to connect
    print "Connecting to database\n ->%s" % (con_string)
 
    # get a connection, if a connect cannot be made an exception will be raised here
    con = psycopg2.connect(con_string)
 
    # conn.cursor will return a cursor object, you can use this cursor to perform queries
    cursor = con.cursor()
    print "Connected!\n"
    cursor.execute("SELECT * FROM users")
    userlist = cursor.fetchall()

    numUsers = 0
    for user in userlist:
        numUsers+=1
        print numUsers
    

except psycopg2.DatabaseError, e:
    print 'Error %s' % e    
    sys.exit(1)
    
    
finally:
    
    if con:
        con.close()