
drop table if exists talks;
create table talks (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  date int(10) unsigned NOT NULL,
  day int(10) unsigned NOT NULL,
  duration int(2) unsigned NOT NULL,
  location varchar(255) NOT NULL default '',
  title varchar(255) NOT NULL,
  overview varchar(255) NOT NULL,
  author_id int(10) unsigned,
  rating  int(2) unsigned NOT NULL default 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table if exists authors;
create table authors (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table if exists comments;
create table comments (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  talk_id int(10) unsigned NOT NULL,
  user_id int(10) unsigned NOT NULL,
  date int(10) unsigned NOT NULL,
  body varchar(255) NOT NULL,
  approved int(1) unsigned NOT NULL default 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table if exists ratings;
create table ratings (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  user_id int(10) unsigned NOT NULL,
  talk_id int(10) unsigned NOT NULL,
  rating int(2) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY(`user_id`,`talk_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table if exists users;
create table users (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  device_id varchar(255) NOT NULL,
  device_type varchar(255),
  device_token varchar(255),
  alerts_enabled int(1) unsigned NOT NULL default 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY(`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table user_schedule (
  user_id int(10) unsigned NOT NULL,
  talk_id int(10) unsigned NOT NULL,
  UNIQUE KEY(`user_id`,`talk_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
