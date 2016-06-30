#!/usr/bin/python
# Will Dolan, Jan 2016
# -*- coding: utf-8 -*-

# DataModel class to facilitate db operations
# using this data model
# db = DataModel('130.64.17.0', JMN, 'jadmin', '***')
import psycopg2
from datetime import date, timedelta
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
		self.conn.autocommit = True


	# destructor
	def __delete__(self,instance):
	     self.db.close()

	     ######## QUERIES ##########

	     #returns all users
	def users_query(self): 
		self.db.execute('SELECT uid,uname,rfid,notes FROM users')
		sel = self.db.fetchall()
		return sel

	     # pass a uid, returns the uid, uname, rfid
	def uid_query(self, uid): 
		sel=self.db.execute('SELECT uid,uname,rfid FROM users WHERE uid = $1')
		return sel(uid)

	     # pass a uname, returns the uid, uname, rfid
	def uname_query(self, uname): 
		self.db.execute("SELECT uid,uname,rfid FROM users WHERE uname = '{0}'".format(uname))
		sel = self.db.fetchall()
		return sel

	     # pass a uname, returns the stations they have permission for
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

	     # pass a uname, returns the stations a list of {uname, station, time} from usage log, ordered by time
	def usage_log_uname_query(self,uname): 
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

	     # returns whole usage log sorted by time
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

		# retuns logs from today.
	def today_logs(self):
		yesterday = date.today() - timedelta(1)
		tomorrow = date.today() + timedelta(1)

		self.db.execute("SELECT * from usage_log ORDER BY time DESC LIMIT 500")
		logs_list = self.db.fetchall()
		for log in logs_list:
			log_date = log[1].day
			if (log_date <= yesterday.day) or (log_date >= tomorrow.day):
				logs_list.remove(log)
		return logs_list

		# returns list of all stations.
	def stations(self):
		self.db.execute("SELECT * FROM stations")
		return self.db.fetchall()

	     ######## ACTIONS ##########

	     # pass info, adds user to database
	def user_add(self,uname,fname,lname,email): 
		try:
			i=self.db.execute("""INSERT INTO users(uid, uname, fname, lname, email) 
							  VALUES (DEFAULT,'{0}','{1}','{2}','{3}')""".format(uname,fname,lname,email))		
		except psycopg2.DatabaseError as e:
			print("Sanity checks failed\n")
			return False 
		else:
			return True

		#pass uid, sid, permission, and sets the permission for the user at that station
	def set_station_permission(self, uid, sid, permission):
		self.db.execute('SELECT * FROM permissions WHERE uid = {0} AND sid = {1}'.format(uid, sid))
		permission_exists = self.db.fetchall()

		if len(permission_exists) > 0:
			i=self.db.execute("""UPDATE permissions SET access = '{2}' 
							WHERE uid = {0} AND sid = {1}""".format(uid, sid, permission))
			print "updating user {0} station {1}".format(uid, sid)
		else:
			i=self.db.execute("""INSERT INTO permissions (uid, sid, access) 
								VALUES ({0}, {1}, '{2}')""".format(uid, sid, permission))
			print "creating permission {0} station {1}".format(uid, sid)




