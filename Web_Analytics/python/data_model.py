#!/usr/bin/python
# Will Dolan, Jan 2016
# -*- coding: utf-8 -*-

# DataModel class to facilitate db operations
# using this data model
# db = DataModel('130.64.17.0', JMN, 'jadmin', '***')
import psycopg2
import sys
import string


class DataModel: 
	# constructor 
	def __init__(self, host, database, user, password): 
		self.conn=psycopg2.connect(
			host=host, 
			database=database, 
			user=user, 
			password=password
			)
		self.db = self.conn.cursor()

	# destructor
	def __delete__(self,instance):
	     self.db.close()

	def user_add(self,uname,fname,lname,email,rfid): 
		i=self.db.execute("INSERT INTO items VALUES (DEFAULT,$1,$2,$3,$4,$5)")
		try:
			i(uname,fname,lname,email,rfid)
		except psycopg2.DatabaseError as e:
			print("Sanity checks failed\n")
			return False 
		else:
			return True

	def users_query(self): 
		self.db.execute('SELECT uid,uname,rfid,notes FROM users')
		sel = self.db.fetchall()
		return sel

	def uid_query(self, uid): 
		sel=self.db.execute('SELECT uid,uname,rfid FROM users WHERE uid = $1')
		return sel(uid)

	def uname_query(self, uname): 
		self.db.execute("SELECT uid,uname,rfid FROM users WHERE uname ='dolanwill'")
		sel = self.db.fetchall()
		return sel

	def permissions_query(self, uname): 
		compiled = """SELECT u.uname as username, 
        s.name as station, p.access as access 
        FROM users as u
        LEFT JOIN permissions as p ON(u.uid = p.uid)
        LEFT JOIN stations as s ON(s.sid = p.sid)
        WHERE u.uname = '{0}'
        ORDER BY username ASC;""".format(uname)

		self.db.execute(compiled)
		sel = self.db.fetchall()
		return sel

	def usage_log_uname_query(self): 
		compiled = """SELECT u.uname as username, 
        s.name as station, ul.time
        FROM usage_log as ul
        LEFT JOIN users as u ON(u.uid = ul.uid)
        LEFT JOIN stations as s ON(s.sid = ul.sid)
        WHERE u.uname = '{0}'
        ORDER BY ul.time ASC;""".format(uname)
	    
		self.db.execute(compiled)
		sel = self.db.fetchall()
		return sel

	def usage_log_query(self): 
		compiled = """SELECT u.uname as username, 
        s.name as station, ul.time 
        FROM usage_log as ul
        LEFT JOIN users as u ON(u.uid = ul.uid)
        LEFT JOIN stations as s ON(s.sid = ul.sid)
        ORDER BY ul.time ASC;"""

		self.db.execute(compiled)
		sel = self.db.fetchall()
		return sel



