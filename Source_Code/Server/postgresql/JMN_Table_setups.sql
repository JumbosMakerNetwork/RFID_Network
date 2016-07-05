-- Notes for table setups in JMN database


-- The following commands will list out the columns and their datatype
-- SELECT column_name, data_type
-- FROM   information_schema.columns
-- WHERE  table_name = 'foo'
-- ORDER  BY ordinal_position;

-- For simplifying data handling by assigning int codes

CREATE TABLE departments(
    deptid      serial PRIMARY KEY,
    dept       text
    );

INSERT INTO departments VALUES (default /*deptid*/ , text /*dept*/);

INSERT INTO departments (deptid, dept) VALUES
    (default,'Anthropology'),
    (default,'Art and Art History'),
    (default,'Biology'),
    (default,'Chemistry'),
    (default,'Child Study and Human Development'),
    (default,'Classics'),
    (default,'Computer Science'),
    (default,'Drama and Dance'),
    (default,'Earth and Ocean Sciences'),
    (default,'Economics'),
    (default,'Education'),
    (default,'Biomedical Engineering'),
    (default,'Chemical and Biological Engineering '),
    (default,'Civil and Environmental Engineering'),
    (default,'Education Engineering'),
    (default,'Electrical and Computer Engineering'),
    (default,'Engineering Management'),
    (default,'Mechanical Engineering'),
    (default,'English'),
    (default,'German, Russian, and Asian Languages/Literature'),
    (default,'History'),
    (default,'Mathematics'),
    (default,'Music'),
    (default,'Occupational Therapy'),
    (default,'Philosophy'),
    (default,'Physical Education'),
    (default,'Physics and Astronomy'),
    (default,'Political Science'),
    (default,'Psychology'),
    (default,'Religion'),
    (default,'Romance Languages'),
    (default,'Sociology'),
    (default,'Urban and Environmental Policy and Planning');

CREATE TABLE relationship(
    rel_id  serial PRIMARY KEY,
    rel     text
    );

INSERT INTO relationships VALUES (default /*rel_id*/, rel /*text*/);

INSERT INTO relationship (rel_id, rel) VALUES
    (default, 'Undergrad'),
    (default, 'Grad - Masters'),
    (default, 'Grad - PhD'),
    (default, 'Staff'),
    (default, 'Faculty'),
    (default, 'Community Member');

CREATE TABLE tool (
    tid             serial PRIMARY KEY,
    tool_type       text,
    description     text
    );

INSERT INTO tool VALUES (default /*TID*/, tool_type /*text*/, desciption /*text*/);

INSERT INTO tool (TID, tool_type, description) VALUES
    (default, 'Hand', 'Hand powered'),
    (default, 'CNC', 'Computer Numerically Controlled'),
    (default, '3D Printer', 'Primary purpose is 3D printing'),
    (default, 'woodworking', 'primary purpose is for wood working'),
    (default, 'metalworking', 'primary purpose is for metal working'),
    (default, 'electronics', 'primary purpose is for working with electrical components'),
    (default, 'textiles', 'primary purpose is for working with textiles'),
    (default, 'computer', 'computational tool'),
    (default, 'laser', 'Primary component is a laser');


CREATE TABLE locations (
    LID             serial PRIMARY KEY,
    name            text,
    description     text,
    address         text,
    Prim_users      integer
    );

INSERT INTO locations values (LID /*serial PRIMARY KEY*/, name /*text*/, description /*text*/, address /*text*/, Prim_users /*integer*/);
-- Examples from our setup
INSERT INTO locations VALUES (default, 'Jumbo''s Maker Studio', 'Test information blah blah blah', '200 Boston Ave Suite G810 Medford MA 02155', default);
INSERT INTO locations VALUES (default, 'The Crafts Center', 'TCU-funded free student-run arts and crafts makerspace', 'Lewis Hall Basement Medford MA 02155', default);
INSERT INTO locations VALUES (default, 'Machine Shop', 'Machine Shop in Bray Lab', 'Bray Lab Medford MA 02155', default);
INSERT INTO locations VALUES (default, 'Creativity Space', '2nd Floor Design Space in Bray Lab', 'Bray Lab Medford MA 02155', default);

-- 

CREATE TABLE users (
    UID         serial PRIMARY KEY,
    uname       text unique,
    fname       text,
    lname       text,
    email       text unique, -- Primary email address
    Temail      text unique, -- Tufts email address
    rfid        bytea unique, -- Hex format for postgreql is E'\\x420c0e11'
    reg_date    date DEFAULT CURRENT_DATE,
    exp_date    date DEFAULT CURRENT_DATE + interval '5 months',
    dept        integer REFERENCES departments (deptid),
    class       integer, -- Expected graduating class
    byear       integer, -- Calculate this from age entered during registration
    lvis        date DEFAULT CURRENT_DATE,-- Last time visitng any space
    Prim_Loc    integer REFERENCES locations (LID),
    rel         integer REFERENCES relationship (rel_id),
    Notes       text
    );

INSERT INTO users VALUES users ( default /* UID-serial PRIMARY KEY*/, uname /* text-unique*/, fname /* text*/, lname /* text*/, email /* text unique*/, Temail /* text unique*/, rfid /* bytea unique*/, reg_date /* date DEFAULT CURRENT_DATE*/, exp_date /* date DEFAULT CURRENT_DATE + interval '5 months'*/, dept /* integer REFERENCES departments (deptid)*/, class /* integer*/, byear /* integer*/, lvis /* date DEFAULT CURRENT_DATE*/, Prim_Loc /* integer REFERENCES locations (LID)*/, rel /* integer REFERENCES relationship (rel_id)*/, Notes /* text*/, );

INSERT INTO users VALUES (default, 'Testuser7', 'Test', 'User', 'testuser7@gmail.com', 'tuser7@tufts.edu', default, default, default, 19, 2017, 1990, default, default, 3, default);
INSERT INTO users VALUES (default, 'Johnathan', 'Doe', 'JDoe', 'JohnDoe@gmail.com', 'Johnathan.Doe@tufts.edu', default, default, default, 19, 2017, 1990, default, default, 3, default);



CREATE TABLE stations (
    SID             serial PRIMARY KEY,
    type_primary    integer REFERENCES tool(TID), -- Primary Tool Category
    tool_secondary  integer REFERENCES tool(TID), -- Secondary Tool Category (If applicable)
    name            text,
    description     text,
    loc             integer REFERENCES locations (LID), -- This references the LID from the table locations
    setup_date      date DEFAULT CURRENT_DATE,
    maintenance     date, -- Last date of maintenance
    maint_interval  interval DAY DEFAULT '60 days',
    Access_exp      interval YEAR TO MONTH DEFAULT '1 years 0 months',
    luse            timestamp DEFAULT current_timestamp, --Last time used
    uses            integer DEFAULT 0,
    hours           interval hour to minute DEFAULT '0 days 0:00:00',
    Notes           text
    );

INSERT INTO stations VALUES (SID /* serial PRIMARY KEY */, type_primary /* integer REFERENCES tool(TID) */, tool_secondary /* integer REFERENCES tool(TID) */, name /* text */, description /* text */, loc /* integer REFERENCES locations (LID) */, setup_date /* date DEFAULT CURRENT_DATE */, maintenance /* date */, maint_interval /* interval DAY DEFAULT '60 days' */, Access_exp /* interval YEAR TO MONTH DEFAULT '1 years 0 months' */, luse /* timestamp DEFAULT current_timestamp */, uses /* integer DEFAULT 0 */, hours /* interval hour to minute DEFAULT '0 days 0:00:00' */, Notes /* text */, );
INSERT INTO stations VALUES (default, default, default, 'laser', '40 Watt Zing 24', 1, default, default, default, default, default, default, default, default, default);

CREATE TABLE permissions (
    SID         integer REFERENCES stations (SID),
    UID         integer REFERENCES users (UID),
    access      boolean default false,
    reg_date    date,
    exp_date    date, -- This needs to be calculated at registration, probably in the php
    luse        timestamp without time zone, --Last time used
    uses        integer DEFAULT 0,
    time_used   interval hour to second DEFAULT '0 days 0:00:00',
    AVG_use     interval hour to second,
    AVG_period  integer,
    Notes       text
    );

INSERT INTO permissions VALUES (SID /* integer REFERENCES stations (SID) */, UID /* integer REFERENCES users (UID) */, access /* boolean default false */, reg_date /* date */, exp_date /* date */, luse /* timestamp without time zone */, uses /* integer DEFAULT 0 */, time_used /* interval hour to second DEFAULT '0 days 0:00:00' */, AVG_use /* interval hour to second */, AVG_period /* integer */, Notes /* text */, );

INSERT INTO permissions VALUES (12, 1, true, default, default, default, default, default, default, default, default);

INSERT INTO permissions VALUES (1, 13, true, CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, 0, default);

CREATE TABLE usage_log(
    log         serial PRIMARY KEY,
    time        timestamp default current_timestamp,
    UID         integer REFERENCES users (UID),
    SID         integer REFERENCES stations (SID),
    req_type    integer, -- 1 is an ask, a 2 is a tell, and 3 is for a tap in expecting an associated tap out eventually
    response    text, -- usually boolean but sometimes N/A
    info        text,
    IP          inet -- Need to occassionally spot check for erroneous logs.
    );

INSERT INTO usage_log VALUES (log /* serial PRIMARY KEY */, time /* timestamp default current_timestamp */, UID /* integer REFERENCES users (UID) */, SID /* integer REFERENCES stations (SID) */, req_type /* integer */, response /* text */, info /* text */, IP /* inet */);
INSERT INTO usage_log VALUES (default, default, 1, 1, 1, 'true', default);

CREATE TABLE Admin_log(
    log         serial PRIMARY KEY,
    time        timestamp default current_timestamp,
    admin       integer REFERENCES users (UID), -- Admin who created the 
    UID         integer REFERENCES users (UID), -- User the log pertains to, if applicable
    SID         integer REFERENCES stations (SID), -- For the station involced
    action      text,
    Notes       text,
    IP          inet -- Need to occassionally spot check for erroneous logs.
    );

INSERT INTO Admin_log VALUES (log /* serial PRIMARY KEY */, time /* timestamp default current_timestamp */, admin /* integer REFERENCES users (UID) */, UID /* integer REFERENCES users (UID) */, SID /* integer REFERENCES stations (SID) */, action /* text */, Notes /* text */, IP /* inet */ );

INSERT INTO Admin_log VALUES (default, default, UID, action, Notes, default);

CREATE TABLE training(
    trid        serial PRIMARY KEY,
    Loc_sp      boolean, -- If training is only valid for a specific location
    loc         integer REFERENCES locations (LID),
    sid_sp      boolean, -- If training is only valid for a specific station
    sid         integer REFERENCES stations (SID),
    tool_sp     boolean, -- If training is only valid for a specific tool type
    tool        integer REFERENCES tool (TID),
    author      integer REFERENCES users (UID), -- Person to create it
    editor      integer REFERENCES users (UID), -- Last person to edit it
    reg_date    date DEFAULT CURRENT_DATE,
    Access_exp  interval MONTH -- if NULL then no expitation 
    );

INSERT INTO training VALUES (trid /* serial PRIMARY KEY */, Loc_sp /* boolean */, loc /* integer REFERENCES locations (LID) */, sid_sp /* boolean */, sid /* integer REFERENCES stations (SID) */, tool_sp /* boolean */, tool /* integer REFERENCES tool (TID) */, author /* integer REFERENCES users (UID) */, editor /* integer REFERENCES users (UID) */, reg_date /* date DEFAULT CURRENT_DATE */, Access_exp /* interval MONTH */);

CREATE TABLE Training_log(
    tr_log      serial PRIMARY KEY,
    time        timestamp default current_timestamp,
    UID         integer REFERENCES users (UID), -- User who took the training
    trid        integer REFERENCES users (trid),
    Passed      boolean, -- Whether they passed or failed
    Notes       text,
    IP          inet -- Need to occassionally spot check for erroneous logs.
    );

INSERT INTO Training_log VALUES(tr_log /* serial PRIMARY KEY */, time /* timestamp default current_timestamp */, UID /* integer REFERENCES users (UID) */, trid /* integer REFERENCES users (trid) */, Passed /* boolean */, Notes /* text */, IP /* inet */);

CREATE TABLE Training_Status(
    UID         integer REFERENCES users (UID),
    trid        integer REFERENCES training (trid),
    Current     boolean,
    expires     date,
    Notes       text
    );


CREATE TABLE roll_call(
    UID         integer REFERENCES users (UID) unique,
    loc_cur     integer REFERENCES locations (LID),
    ent         timestamp DEFAULT current_timestamp
    );

INSERT INTO roll_call VALUES (18, 4, default), (19, 4, default), (20, 4, default), (21, 4, default);

GRANT SELECT ON roll_call TO jadmin;
GRANT INSERT ON roll_call TO jadmin;
GRANT UPDATE ON roll_call TO jadmin;
GRANT USAGE ON roll_call_uid_fkey TO jadmin;
GRANT USAGE ON roll_call_loc_cur_fkey TO jadmin;




-- Add rows for testing purposes

INSERT INTO users VALUES (default, 'Test', 'User', 123456789, CURRENT_DATE, 'Mech Eng', 2017, default);
INSERT INTO users VALUES (default, 'Test2', 'User2', 987654321, CURRENT_DATE, 'STEM ed', 2017, default);


INSERT INTO locations VALUES (default, 'Jumbo''s Maker Studio', '200 Boston Ave');

INSERT INTO stations VALUES (default, 'laser', '40 Watt Zing 24', 1, default, default, default, default, default);

INSERT INTO permissions VALUES (1, 1, true, CURRENT_DATE, CURRENT_TIMESTAMP, 0, default);
INSERT INTO permissions VALUES (1, 2, false, CURRENT_DATE, CURRENT_TIMESTAMP, 0, default);



-- Test urls 
http://192.168.1.140/index.php?stid=1&rfid=123456789&req=1
http://192.168.1.140/index.php?stid=1&rfid=987654321&req=1

-- Create users for the terminals and administrators

CREATE USER jumbo WITH PASSWORD 'Jumbo_pw7';
CREATE USER jadmin WITH PASSWORD 'jadmin_pw7';

-- For granting permissions to users

GRANT CONNECT ON DATABASE "JMN" TO jumbo;
GRANT CONNECT ON DATABASE "JMN" TO jadmin;

GRANT SELECT ON tool TO  jadmin;
GRANT SELECT ON locations TO  jadmin;

GRANT INSERT ON users TO jumbo;
GRANT SELECT ON permissions TO  jumbo;
GRANT SELECT ON departments TO  jumbo;
GRANT SELECT ON relationship TO  jumbo;

GRANT INSERT ON users TO jadmin;
GRANT UPDATE ON users_uid_seq TO jadmin;
GRANT SELECT ON permissions TO  jadmin;
GRANT INSERT ON permissions TO jadmin;
GRANT SELECT ON departments TO  jadmin;
GRANT SELECT ON relationship TO  jadmin;
GRANT INSERT ON admin_log TO jadmin;
GRANT UPDATE ON admin_log_log_seq TO jadmin;
GRANT INSERT ON stations TO jadmin;
GRANT UPDATE ON stations_sid_seq TO jadmin;
GRANT INSERT ON tool TO jadmin;
GRANT UPDATE ON tool_tid_seq TO jadmin;
GRANT INSERT ON usage_log TO jadmin;
GRANT UPDATE ON usage_log_log_seq TO jadmin;
GRANT SELECT ON tool TO jadmin;
GRANT SELECT ON locations TO jadmin;


GRANT UPDATE (uses) ON permissions TO  jumbo;
GRANT UPDATE (luse) ON permissions TO  jumbo;
GRANT UPDATE (time_used) ON permissions TO  jumbo;
GRANT INSERT ON usage_log TO jumbo;
GRANT INSERT ON usage_log TO jadmin;
GRANT INSERT ON Admin_log TO jadmin;
GRANT USAGE ON sequence usage_log_log_seq TO jumbo;
GRANT USAGE ON sequence Admin_log_log_seq TO jadmin;






-- This is a dummy table used for tested out things. Expected to be dropped and remade
-- with new columns and/or data types on several occasions. 
CREATE TABLE users_test (
    UID         serial PRIMARY KEY,
    uname       text unique,
    fname       text,
    rfid        bytea unique, -- Hex format for postgreql is E'\\x420c0e11'
    reg_date    date DEFAULT CURRENT_DATE,
    lvis        date DEFAULT CURRENT_DATE -- Last time visitng any space
    );

INSERT INTO users_test VALUES (default, 'PupleStaff', 'Donatello', E'\\x420c0e11', default, NULL);
INSERT INTO users_test VALUES (default, 'OrangeNunchucks', 'Michaelangelo', E'\\x52F1ADE1', default, NULL);
INSERT INTO users_test VALUES (default, 'BlueSwords', 'Leonardo', E'\\x110e0c42', default, NULL);
INSERT INTO users_test VALUES (default, 'RedSai', 'Rapheal', E'\\xe1adf152', default, NULL);

CREATE TABLE permissions_test (
    SID         integer REFERENCES stations (SID),
    UID         integer REFERENCES users_test (UID),
    access      boolean default false,
    reg_date    date,
    luse        timestamp without time zone, --Last time used
    uses        integer DEFAULT 0,
    time_used   interval hour to second DEFAULT '0 days 0:00:00'
    );

INSERT INTO permissions_test VALUES (2, 1, true, CURRENT_DATE, default, default, default);
INSERT INTO permissions_test VALUES (2, 2, false, CURRENT_DATE, default, default, default);
INSERT INTO permissions_test VALUES (2, 3, true, CURRENT_DATE, default, default, default);
INSERT INTO permissions_test VALUES (2, 4, false, CURRENT_DATE, default, default, default);
