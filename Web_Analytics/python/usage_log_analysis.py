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
month_logs = [0] * 5

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
    pass


# map the inputs to the function blocks
options = {1 : jan,
	       2 : feb,
           9 : sept,
           10 : oc,
           11 : nov,
           12 : dec,
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

s = str(month_logs)
print s
print "[sept, oct, nov, dec, jan]"

# now write the usage array to a .txt file
filename = 'monthly_log_count.txt'
f = open(filename, 'w')
f.truncate()
# write the stats to the file
f.write(s)
f.close()

