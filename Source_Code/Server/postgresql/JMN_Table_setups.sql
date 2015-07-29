-- Notes for table setups in JMN database


-- The following commands will list out the columns and their datatype
-- SELECT column_name, data_type
-- FROM   information_schema.columns
-- WHERE  table_name = 'foo'
-- ORDER  BY ordinal_position;

ALTER TABLE products ALTER COLUMN price TYPE numeric(10,2);

CREATE TABLE users (
    UID         serial PRIMARY KEY,
    uname       text unique,
    fname       text,
    lname       text,
    email       text unique, -- Primary email address
    Temail      text unique, -- Tufts email address
    rfid        bigint unique,
    reg_date    date DEFAULT CURRENT_DATE,
    exp_date    date DEFAULT CURRENT_DATE + interval '5 months',
    dept        integer REFERENCES departments (deptid),
    class       integer, -- Expected graduating class
    byear       integer, -- Calculate this from age entered during registration
    lvis        date DEFAULT CURRENT_DATE,-- Last time visitng any space
    Prim_Loc    integer,
    rel         integer REFERENCES relationship (rel_id),
    Notes       text
    );

INSERT INTO users VALUES (default, 'Testuser7', 'Test', 'User', 'testuser7@gmail.com', 'tuser7@tufts.edu', default, default, default, 19, 2017, 1990, default, default, 3, default);

CREATE TABLE locations (
    LID             serial PRIMARY KEY,
    name            text,
    description     text,
    address         text,
    Prim_users      integer
    );

INSERT INTO locations VALUES (default, 'Jumbo''s Maker Studio', 'Test information blah blah blah', '200 Boston Ave Suite G810 Medford MA 02155', default);

CREATE TABLE stations (
    SID            serial PRIMARY KEY,
    name            text,
    description     text,
    loc             integer REFERENCES locations (lid),
    setup_date      date DEFAULT CURRENT_DATE,
    maintenance     date DEFAULT CURRENT_DATE, -- Last date of maintenance
    maint_interval  interval DAY DEFAULT '60 days',
    Access_exp      interval YEAR TO MONTH DEFAULT '1 years 0 months',
    luse            timestamp DEFAULT current_timestamp, --Last time used
    uses            integer DEFAULT 0,
    hours           interval hour to minute DEFAULT '0 days 0:00:00',
    Notes           text
    );

INSERT INTO stations VALUES (default, 'laser', '40 Watt Zing 24', 1, default, default, default, default, default, default, default, default);

CREATE TABLE permissions (
    SID         integer REFERENCES stations (SID),
    UID         integer REFERENCES users (UID),
    access      boolean default false,
    reg_date    date,
    exp_date    date, -- This needs to be calculated at registration, probably in the php
    luse        timestamp without time zone, --Last time used
    uses        integer DEFAULT 0,
    time_used   interval hour to second DEFAULT '0 days 0:00:00',
    Notes       text
    );

INSERT INTO permissions VALUES (1, 1, true, CURRENT_DATE, CURRENT_DATE, CURRENT_TIMESTAMP, 0, default);

CREATE TABLE usage_log(
    log         serial PRIMARY KEY,
    time        timestamp default current_timestamp,
    UID         integer REFERENCES users (UID),
    SID         integer REFERENCES stations (SID),
    req_type    integer, -- 1 is an ask and a 2 is a tell
    response    text, -- usually boolean but sometimes N/A
    info        text
    );

INSERT INTO usage_log VALUES (default, default, 1, 1, 1, 'true', default);

CREATE TABLE Admin_log(
    log         serial PRIMARY KEY,
    time        timestamp default current_timestamp,
    UID         integer REFERENCES users (UID),
    action      text,
    Notes       text
    );

INSERT INTO Admin_log VALUES (default, default, 1, 'database check', default);

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

CREATE USER jumbo WITH PASSWORD 'Jumbo_password7';
CREATE USER jadmin WITH PASSWORD 'JAdmin_password7';

-- For granting permissions to users

GRANT CONNECT ON DATABASE "JMN" TO jumbo;
GRANT CONNECT ON DATABASE "JMN" TO jadmin;
GRANT SELECT ON users TO  jumbo;
GRANT SELECT ON permissions TO  jumbo;
GRANT UPDATE (uses) ON permissions TO  jumbo;
GRANT UPDATE (luse) ON permissions TO  jumbo;
GRANT INSERT ON usage_log TO jumbo;
GRANT INSERT ON Admin_log TO jadmin;
GRANT INSERT ON users TO jadmin;
GRANT USAGE ON sequence usage_log_log_seq TO jumbo;
GRANT USAGE ON sequence Admin_log_log_seq TO jadmin;


-- For simplifying data handling 

CREATE TABLE departments(
    deptid      serial PRIMARY KEY,
    dept       text
    );

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

INSERT INTO relationship (rel_id, rel) VALUES
    (default, 'Undergrad'),
    (default, 'Grad - Masters'),
    (default, 'Grad - PhD'),
    (default, 'Staff'),
    (default, 'Faculty'),
    (default, 'Community Member');





