\set ECHO 0
BEGIN;
\i sql/user_info.sql
\set ECHO all

-- create empty role
CREATE ROLE foo;

-- nothing yet owned by foo
SELECT type, relname, rights FROM accessible_objects('foo');

CREATE TABLE test_table (id INT);
GRANT ALL ON test_table TO foo;

SELECT type, relname, rights FROM accessible_objects('foo');

ROLLBACK;
