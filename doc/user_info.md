user_info
=========

Provides basic info about users - what roles are granted to them
(recursively), what objects they own and so on.


Available functions
-------------------

The following functions list objects owned by a given user, referenced
by OID or user name or (in case of the parameter-less function) current
user.

 * **user\_objects**`(p_user_oid OID)`
 * **user\_objects**`(p_user OID)`
 * **user\_objects**`()`

Using them is pretty simple

    CREATE ROLE user_foo;
    CREATE TABLE table_bar (id INT);
    ALTER TABLE table OWNER TO user_foo;

    SELECT * FROM user_objects('user_foo');
    
       type   |   oid   | schema |    name    
    ----------+---------+--------+------------
     TYPE     | 1525456 | public | table_bar
     TYPE     | 1525455 | public | _table_bar
     RELATION | 1525454 | public | table_bar
     TABLE    |         | public | table_bar
    (4 rows)

and similarly for the other functions. The information are read from
system catalogs and may contain duplicities (as for example the two
lines for `table_bar` table - one for `RELATION` and `TABLE` above).

There are also functions listing roles granted to a role/user - basic

 * **granted\_roles**`(p_user_oid OID)`
 * **granted\_roles**`(p_role_name NAME)`
 * **granted\_roles**`()`

and a pretty-printing versions

 * **granted\_roles\_pretty**`(p_user_oid OID)`
 * **granted\_roles\_pretty**`(p_role_name NAME)`
 * **granted\_roles\_pretty**`()`

Again, using those functions is quite straightforward - just pass in
a role name and you'll get a list of granted roles.

    CREATE ROLE foo;
    CREATE ROLE bar;
    GRANT bar TO foo;

    SELECT * FROM granted_roles('foo');
    
      id  | name | grant_to_id | grant_to_name |    path     | level 
    ------+------+-------------+---------------+-------------+-------
     5458 | foo  |             |               | {5458}      |     0
     5459 | bar  |        5458 | role_foo      | {5458,5459} |     1
    (2 rows)
    
    SELECT * FROM granted_roles_pretty('foo');

     id   | name  |    path     | plain_name 
    ------+-------+-------------+------------
     5458 | foo   | {5458}      | foo
     5459 |   bar | {5458,5459} | bar
    (2 rows)

The last function provides info about granted privileges for various
objects - the current version considers only explicitly granted
privileges (i.e. not handle default privileges) and only privileges
granted to a particular role (i.e. not through other roles).

 * **accessible\_objects**`(p_role_oid OID)`
 * **accessible*_objects**`(p_role_name NAME)`

The usage is quite simple and the output is a list (table) of objects
with an information about granted privileges:

    SELECT * FROM accessible_objects(10);

       type   | id    |        relname        |      rights
    ----------+-------+-----------------------+----------------------
     RELATION | 11713 | foreign_servers       | {INSERT,SELECT,...}
     RELATION | 11720 | foreign_table_options | {INSERT,SELECT,...}
     RELATION | 11723 | foreign_tables        | {INSERT,SELECT,...}
     RELATION | 11729 | user_mapping_options  | {INSERT,SELECT,...}
     RELATION | 11733 | user_mappings         | {INSERT,SELECT,...}
     RELATION | 11591 | sql_features          | {INSERT,SELECT,...}
     DATABASE |     1 | template1             | {CREATE,TEMPORARY,...}
     DATABASE | 12006 | template0             | {CREATE,TEMPORARY,...}
     SCHEMA   |    11 | pg_catalog            | {USAGE,CREATE}
     SCHEMA   |  2200 | public                | {USAGE,CREATE}
     SCHEMA   | 11468 | information_schema    | {USAGE,CREATE}

The ability to handle default privileges, privileges granted through
other roles and ability to identify how exactly a user got a particular
privilege is a TODO for future.


Installation
------------
Installing this extension is very simple - if you're using pgxn client
(and you should), just do this:

    $ pgxn install --testing user_info
    $ pgxn load --testing -d mydb user_info

You can also install manually, just it like any other extension, i.e.

    $ make install
    $ psql dbname -c "CREATE EXTENSION user_info"

And if you're on an older PostgreSQL version, you have to run the SQL
script manually (use the proper version).

    $ psql dbname < user_info--0.1.sql

That's all.

Support
-------

This extension is hosted on github, including bug tracker and so on:

    https://github.com/tvondra/user_info

You may also contact me directly at tv@fuzzy.cz.

Author
------

Tomas Vondra <tv@fuzzy.cz>

License
-------
This software is distributed under the terms of BSD 2-clause license.
See LICENSE or http://www.opensource.org/licenses/bsd-license.php for
more details.