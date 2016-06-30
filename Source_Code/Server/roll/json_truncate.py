#!/usr/bin/python
# -*- coding: utf-8 -*-

# This is the code for  assigning 'true' permission for each station
# when a new user gets added. One must "pass" the uid number into this function.
 
import sys

fo = open("bray_roll.json", "w")
fo.truncate()
fo.close()

fo = open("CEEO_roll.json", "w")
fo.truncate()
fo.close()