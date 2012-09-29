\set ECHO 0
BEGIN;
\i sql/user_info.sql
\set ECHO all

-- create empty role
CREATE ROLE foo;

-- should return one row (the role itself)
SELECT count(*) FROM granted_roles('foo');

-- create another role and grant it to foo
CREATE ROLE bar;
GRANT bar TO foo;

-- should return two lines
SELECT count(*) FROM granted_roles('foo');

ROLLBACK;
