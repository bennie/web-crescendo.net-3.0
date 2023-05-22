-- MySQL dump 8.23
--
-- Host: localhost    Database: bingo
---------------------------------------------------------
-- Server version	3.23.58

--
-- Table structure for table `access`
--

CREATE TABLE access (
  id int(11) NOT NULL default '0',
  count int(11) default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Dumping data for table `access`
--


INSERT INTO access VALUES (1,109);
INSERT INTO access VALUES (2,108);

--
-- Table structure for table `info`
--

CREATE TABLE info (
  id int(11) NOT NULL auto_increment,
  title varchar(25) default NULL,
  face varchar(255) default NULL,
  modified timestamp(14) NOT NULL,
  created timestamp(14) NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Dumping data for table `info`
--


INSERT INTO info VALUES (1,'Triggur','triggur-face.jpg',20050801145344,20030306120101);
INSERT INTO info VALUES (2,'Giza','giza-face.jpg',20050801145423,20050801104501);

--
-- Table structure for table `tiles`
--

CREATE TABLE tiles (
  ai int(11) NOT NULL auto_increment,
  id int(11) NOT NULL default '0',
  tile varchar(255) NOT NULL default '',
  PRIMARY KEY  (ai)
) TYPE=MyISAM;

--
-- Dumping data for table `tiles`
--


INSERT INTO tiles VALUES (1,1,'MAV!\r');
INSERT INTO tiles VALUES (2,1,'Poking Kage\r');
INSERT INTO tiles VALUES (3,1,'Poking Giza\r');
INSERT INTO tiles VALUES (4,1,'Poking Points\r');
INSERT INTO tiles VALUES (5,1,'Poking Rigel\r');
INSERT INTO tiles VALUES (6,1,'Triggur squints\r');
INSERT INTO tiles VALUES (7,1,'Harrumph!\r');
INSERT INTO tiles VALUES (8,1,'Some exotic vacation\r');
INSERT INTO tiles VALUES (9,1,'*BURP*\r');
INSERT INTO tiles VALUES (10,1,'*FART*\r');
INSERT INTO tiles VALUES (11,1,'Mysterious offensive emission\r');
INSERT INTO tiles VALUES (12,1,'Website Work\r');
INSERT INTO tiles VALUES (13,1,'Blinkie lights\r');
INSERT INTO tiles VALUES (14,1,'Costume Work\r');
INSERT INTO tiles VALUES (15,1,'*poke*\r');
INSERT INTO tiles VALUES (16,1,'*ker- POUNCE*\r');
INSERT INTO tiles VALUES (17,1,'Java\r');
INSERT INTO tiles VALUES (18,1,'Rave equipment\r');
INSERT INTO tiles VALUES (19,1,'Lumix\r');
INSERT INTO tiles VALUES (20,1,'Pee Defensively\r');
INSERT INTO tiles VALUES (21,1,'O.o\r');
INSERT INTO tiles VALUES (22,1,'*fist shakes*\r');
INSERT INTO tiles VALUES (23,1,'O.O\r');
INSERT INTO tiles VALUES (24,1,'*fuzzle*\r');
INSERT INTO tiles VALUES (25,1,'*faints dead away*\r');
INSERT INTO tiles VALUES (26,1,'*tosses you a URL*\r');
INSERT INTO tiles VALUES (27,1,'Triggur MENACES!\r');
INSERT INTO tiles VALUES (28,1,'UNFAIR TO HOSSES\r');
INSERT INTO tiles VALUES (29,1,'knocks person over');
INSERT INTO tiles VALUES (30,2,'Poop\r');
INSERT INTO tiles VALUES (31,2,'Poop\r');
INSERT INTO tiles VALUES (32,2,'Poop\r');
INSERT INTO tiles VALUES (33,2,'Spam Email\r');
INSERT INTO tiles VALUES (34,2,'AC\r');
INSERT INTO tiles VALUES (35,2,'Cheetah toys\r');
INSERT INTO tiles VALUES (36,2,'PHP\r');
INSERT INTO tiles VALUES (37,2,'Giza Bites\r');
INSERT INTO tiles VALUES (38,2,'Drinking Al-kee-haul');
INSERT INTO tiles VALUES (39,2,'Gas\r');
INSERT INTO tiles VALUES (40,2,'Fiber');
INSERT INTO tiles VALUES (41,2,'Giza humps Tailen');

