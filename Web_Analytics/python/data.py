#!/usr/bin/python
# Will Dolan
# -*- coding: utf-8 -*-

import psycopg2
import data_model
import sys

database =data_model.DataModel('130.64.17.0', 'JMN', 'dolanwill', 'password7')
q = database.usage_log_query()
print q 
