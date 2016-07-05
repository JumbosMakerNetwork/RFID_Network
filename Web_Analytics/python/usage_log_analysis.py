#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

import time
import psycopg2
import sys
import json
import data_model



con = None

# array to hold num logs for each month. order goes sept,oc,nov,dec,jan
# ex. month_logs[1] == 20 means there were 20 logs in oct
month_logs = [0] * 12

# define the month function blocks
def sept():
    month_logs[0] += 1
def oc():
    month_logs[1] += 1
def nov():
    month_logs[2] += 1
def dec():
    month_logs[3] += 1
def jan():
    month_logs[4] += 1
def feb():
    month_logs[5] += 1
def mar():
    month_logs[6] += 1
def apr():
    month_logs[7] += 1
def may():
    month_logs[8] += 1
def june():
    month_logs[9] += 1
def july():
    month_logs[10] += 1


# map the inputs to the function blocks
options = {1 : jan,
           2 : feb,
           3 : mar,
           4 : apr,
           5 : may,
           6 : june,
	         7 : july,
           9 : sept,
           10 : oc,
           11 : nov,
           12 : dec
}

database =data_model.DataModel('130.64.17.0', 'JMN', 'dolanwill', 'xxx')
log_list = database.usage_log_query()

numLogs = 0
for log in log_list:
    cur_month = (log_list[numLogs][2]).month
    options[cur_month]()
    numLogs+=1
print "Usage log report: "
print "sept count: " + str(month_logs[0])
print "oct count: " + str(month_logs[1])
print "nov count: " + str(month_logs[2])
print "dec count: " + str(month_logs[3])
print "jan count: " + str(month_logs[4])
print "feb count: " + str(month_logs[5])
print "mar count: " + str(month_logs[6])
print "apr count: " + str(month_logs[7])
print "may count: " + str(month_logs[8])
print "june count: " + str(month_logs[9])
print "july count: " + str(month_logs[10])

s = str(month_logs)
print s
print "[sept, oct, nov, dec, jan, feb, mar, apr, may, june, july]"

# now write the usage array to a .txt file
filename = 'monthly_log_count.txt'
f = open(filename, 'w')
f.truncate()
# write the stats to the file
f.write(s)
f.close()

