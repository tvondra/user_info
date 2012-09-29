\set ECHO 0
BEGIN;
\i sql/user_info.sql
\set ECHO all

-- create empty role
CREATE ROLE foo;

-- nothing yet owned by foo
SELECT * FROM user_objects('foo');

-- create table and alter owner to foo
CREATE TABLE foo_table (id int);
ALTER TABLE foo_table OWNER TO foo;

-- nothing yet owned by foo - both queries should return 4 rows (types+relations)
SELECT count(*) FROM user_objects('foo');
SELECT count(*) FROM user_objects('foo') WHERE name = 'foo';

-- these two should return 1 (or 2 in case of TYPEs)
SELECT count(*) FROM user_objects('foo') WHERE type = 'RELATION';
SELECT count(*) FROM user_objects('foo') WHERE type = 'TABLE';
SELECT count(*) FROM user_objects('foo') WHERE type = 'TYPE';

ROLLBACK;
