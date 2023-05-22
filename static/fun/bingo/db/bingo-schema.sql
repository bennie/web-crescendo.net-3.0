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
-- Table structure for table `tiles`
--

CREATE TABLE tiles (
  ai int(11) NOT NULL auto_increment,
  id int(11) NOT NULL default '0',
  tile varchar(255) NOT NULL default '',
  PRIMARY KEY  (ai)
) TYPE=MyISAM;

