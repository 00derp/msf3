drop table hosts;

create table hosts (
id SERIAL PRIMARY KEY,
created TIMESTAMP,
address VARCHAR(16) UNIQUE,
address6 VARCHAR(255),
mac VARCHAR(255),
comm VARCHAR(255),
name VARCHAR(255),
state VARCHAR(255),
info VARCHAR(1024),
os_name VARCHAR(255),
os_flavor VARCHAR(255),
os_sp VARCHAR(255),
os_lang VARCHAR(255),
arch VARCHAR(255)
);

drop table clients;
create table clients (
id INTEGER PRIMARY KEY NOT NULL,
host_id INTEGER,
created TIMESTAMP,
ua_string VARCHAR(1024) NOT NULL,
ua_name VARCHAR(64),
ua_ver VARCHAR(32)
);

drop table services;

create table services (
id SERIAL PRIMARY KEY,
host_id INTEGER,
created TIMESTAMP,
port INTEGER NOT NULL,
proto VARCHAR(16) NOT NULL,
state VARCHAR(255),
name VARCHAR(255),
info VARCHAR(1024)
);

drop table vulns;

create table vulns (
id SERIAL PRIMARY KEY,
host_id INTEGER,
service_id INTEGER,
created TIMESTAMP,
name VARCHAR(255),
data TEXT
);

drop table refs;

create table refs (
id SERIAL PRIMARY KEY,
ref_id INTEGER,
created TIMESTAMP,
name VARCHAR(512)
);

drop table vulns_refs;

create table vulns_refs (
ref_id INTEGER,
vuln_id INTEGER
);

drop table notes;

create table notes (
id SERIAL PRIMARY KEY,
host_id INTEGER,
created TIMESTAMP,
ntype VARCHAR(512),
data TEXT
);
