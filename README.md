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


License
-------
This software is distributed under the terms of BSD 2-clause license.
See LICENSE or http://www.opensource.org/licenses/bsd-license.php for
more details.