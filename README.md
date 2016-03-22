# Jumbo's Maker Network - RFID Usage Tracking
This project is an RFID tag and arduino based system for tracking use in a makerspace while also integrating automated safety interlocks through use of data and power relays. 

This includes the firmware and hardware files for the system as well as a series of analytical software used to derive insightful data from the makerspace.

This project is currently in development, so if you stumble across this, please let us know if something doesn't work and feel free to comment to help out if you have some useful feedback.


## Hardware
Contains:
	-Eagle Files, used as design for fabricating circuit boards. There are a variety of circuit boards used in this project, the principal ones being a data interlock board used to interrupt serial communication between devices, and a Pro Shield board, which is used to connect all the components of the RFID reader (e.g. the Mifare Scanner, the LCD monitor..) to the Arduino ESP8266
	-Enclosure files, which are CAD schematics for 3d printing/laser cutting the enclosure that holds all the components

## Scripts
Contains:
	-Several scripts used to initialize new stations and users. These funcitons will eventually be encapsulated by a unified Python data model which will be used for all SQL functions.

## Source Code
Contains:
	-Arduino: the necessary libraries and source code needed for the Arduino microcontrollers powering this system. Within this repo are folders for Signin and Relay stations; Signin stations only have the funcitnality of signin/signout, whereas the relay terminals are capable of restricting power or serial communication between devices.
	-All the php and PSQL initialization tools used to create our PSQL database (in scripts and www)

## Web Analytics
Contains:
	-a set of documents that generate an HTML page featuring visualized data of makerspace usage and new membership over time. This data is collected with python scripts using the pyscopg module, and then interpreted with javascript files utilizing ajax and jquery, finally being visualized with the charts.js library.
