/*
 * Author: Tomas Vondra
 * Created at: Sat Sep 29 16:34:48 +0200 2012
 *
 */

-- lists all objects owned by a user (may contain duplicities - e.g.
-- tables may be listed in pg_class and pg_tables, similar for views)
CREATE OR REPLACE FUNCTION user_objects(p_user_oid OID)
    RETURNS TABLE (type TEXT, oid OID, schema name, "name" name)
AS $$ 

    SELECT 'PROCEDURE', p.oid, nspname, proname 
      FROM pg_proc p JOIN pg_namespace n ON (p.pronamespace = n.oid)
     WHERE proowner = p_user_oid

    UNION ALL

    SELECT 'TYPE', t.oid, nspname, typname 
      FROM pg_type t JOIN pg_namespace n ON (t.typnamespace = n.oid)
     WHERE typowner = p_user_oid

    UNION ALL

    SELECT 'RELATION', c.oid, nspname, relname
      FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid)
     WHERE relowner = p_user_oid

    UNION ALL

    SELECT 'OPERATOR', o.oid, nspname, oprname 
      FROM pg_operator o JOIN pg_namespace n ON (o.oprnamespace = n.oid)
     WHERE oprowner = p_user_oid

    UNION ALL

    SELECT 'OPERATOR FAMILY', o.oid, nspname, opfname 
      FROM pg_opfamily o JOIN pg_namespace n ON (o.opfnamespace = n.oid)
     WHERE opfowner = p_user_oid

    UNION ALL

    SELECT 'OPERATOR CLASS', o.oid, nspname, opcname
      FROM pg_opclass o JOIN pg_namespace n ON (o.opcnamespace = n.oid)
     WHERE opcowner = p_user_oid

    UNION ALL

    SELECT 'LANGUAGE', l.oid, NULL, lanname 
      FROM pg_language l
     WHERE lanowner = p_user_oid

--    UNION ALL
--
--    SELECT 'LARGE OBJECT METADATA', l.oid, NULL, lomname 
--      FROM pg_largeobject_metadata l
--     WHERE lomowner = p_user_oid

    UNION ALL

    SELECT 'NAMESPACE', n.oid, NULL, nspname 
      FROM pg_namespace n
     WHERE nspowner = p_user_oid

    UNION ALL

    SELECT 'CONVERSION', c.oid, nspname, conname 
      FROM pg_conversion c JOIN pg_namespace n ON (c.connamespace = n.oid)
     WHERE conowner = p_user_oid

    UNION ALL

    SELECT 'TABLESPACE', t.oid, NULL, t.spcname
      FROM pg_tablespace t
     WHERE spcowner = p_user_oid

    UNION ALL

    SELECT 'TS CONFIG', c.oid, nspname, cfgname
      FROM pg_ts_config c JOIN pg_namespace n ON (c.cfgnamespace = n.oid)
     WHERE cfgowner = p_user_oid

    UNION ALL

    SELECT 'TS DICTIONARY', d.oid, nspname, dictname
      FROM pg_ts_dict d JOIN pg_namespace n ON (d.dictnamespace = n.oid)
     WHERE dictowner = p_user_oid

    UNION ALL

    SELECT 'EXTENSION', e.oid, nspname, extname
      FROM pg_extension e JOIN pg_namespace n ON (e.extnamespace = n.oid)
     WHERE extowner = p_user_oid

    UNION ALL

    SELECT 'FDW', f.oid, NULL, fdwname
      FROM pg_foreign_data_wrapper f
     WHERE fdwowner = p_user_oid

    UNION ALL

    SELECT 'FDW SERVER', s.oid, NULL, srvname
      FROM pg_foreign_server s 
     WHERE srvowner = p_user_oid

    UNION ALL

    SELECT 'COLLATION', c.oid, nspname, collname 
      FROM pg_collation c JOIN pg_namespace n ON (c.collnamespace = n.oid)
     WHERE collowner = p_user_oid

    UNION ALL

    SELECT 'TABLE', NULL, schemaname, tablename
      FROM pg_tables
     WHERE tableowner = (SELECT rolname FROM pg_roles WHERE oid = p_user_oid)
    
    UNION ALL

    SELECT 'VIEW', NULL, schemaname, viewname
      FROM pg_views
     WHERE viewowner = (SELECT rolname FROM pg_roles WHERE oid = p_user_oid)

    UNION ALL

    SELECT 'PREPARED XACT', NULL, NULL, gid
      FROM pg_prepared_xacts
     WHERE owner = (SELECT rolname FROM pg_roles WHERE oid = p_user_oid);

$$ LANGUAGE SQL;

-- same as user_objects(oid), but lists by 
CREATE OR REPLACE FUNCTION user_objects(p_user NAME)
    RETURNS TABLE (type TEXT, oid OID, schema name, "name" name)
AS $$

    SELECT * FROM user_objects((SELECT oid FROM pg_roles WHERE rolname = p_user));

$$ LANGUAGE SQL;

-- list objects owned by the current user
CREATE OR REPLACE FUNCTION user_objects()
    RETURNS TABLE (type TEXT, oid OID, schema name, "name" name)
AS $$

    SELECT * FROM user_objects((SELECT oid FROM pg_roles WHERE rolname = current_user));

$$ LANGUAGE SQL;

-- list roles granted to a user (either directly or through other roles)
CREATE OR REPLACE FUNCTION granted_roles (p_user_oid OID)
    RETURNS TABLE (id OID, name NAME, granted_to_id OID, granted_to_name NAME, path OID[], level INT)
AS $$
    WITH RECURSIVE granted_roles(roleid, rolename, granted_roleid, granted_rolename, path, level) AS (

        -- user's primary role
        SELECT m.member AS roleid, r.rolname AS rolname, g.oid AS granted_roleid, g.rolname AS granted_rolename,
               (CASE WHEN g.oid IS NOT NULL THEN ARRAY[p_user_oid,g.oid] ELSE ARRAY[p_user_oid] END) AS path, 1 AS level
        FROM pg_roles r JOIN pg_auth_members m ON (m.member = r.oid)
                        JOIN pg_roles g ON (m.roleid = g.oid)
        WHERE r.oid = p_user_oid

        UNION ALL

        -- lookup roles granted to the primary role (recursively)
        SELECT m.member AS roleid, r.granted_rolename AS rolname, g.oid AS granted_roleid, g.rolname AS granted_rolename, path || g.oid AS path, r.level+1 AS level
        FROM granted_roles r  JOIN pg_auth_members m ON (m.member = r.granted_roleid)
                                LEFT JOIN pg_roles g ON (m.roleid = g.oid)
        WHERE r.granted_roleid IS NOT NULL

    )
    SELECT * FROM (
        SELECT oid, rolname, NULL::oid, NULL::name, ARRAY[p_user_oid] AS path, 0 AS level FROM pg_roles WHERE oid = p_user_oid
        UNION ALL
        SELECT granted_roleid, granted_rolename, roleid, rolename, path, level FROM granted_roles
    ) foo ORDER BY PATH;
$$ LANGUAGE SQL;

-- list roles granted to a user using username
CREATE OR REPLACE FUNCTION granted_roles (p_role_name NAME)
    RETURNS TABLE (id OID, name NAME, granted_to_id OID, granted_to_name NAME, path OID[], level INT)
AS $$
    SELECT * FROM granted_roles((SELECT oid FROM pg_roles WHERE rolname = p_role_name));
$$ LANGUAGE SQL;

-- list roles granted to the current user (role)
CREATE OR REPLACE FUNCTION granted_roles ()
    RETURNS TABLE (id OID, name NAME, granted_to_id OID, granted_to_name NAME, path OID[], level INT)
AS $$
    SELECT * FROM granted_roles(current_user);
$$ LANGUAGE SQL;

-- list of roles granted to a user - pretty-printed
CREATE OR REPLACE FUNCTION granted_roles_pretty(p_user_oid OID)
    RETURNS TABLE (id OID, name TEXT, path OID[], plain_name NAME)
AS $$
    SELECT id, (CASE WHEN level = 0 THEN name ELSE (repeat('  ', level) || name) END) rolename, path, name AS plain_rolename
    FROM granted_roles(p_user_oid) ORDER BY PATH;
$$ LANGUAGE SQL;

-- list of roles granted to a user by role name - pretty-printed
CREATE OR REPLACE FUNCTION granted_roles_pretty(p_role_name NAME)
    RETURNS TABLE (id OID, name TEXT, path OID[], plain_name NAME)
AS $$
    SELECT * FROM granted_roles_pretty((SELECT oid FROM pg_roles WHERE rolname = p_role_name)) ORDER BY PATH;
$$ LANGUAGE SQL;

-- list of roles granted to the current user - pretty-printed
CREATE OR REPLACE FUNCTION granted_roles_pretty()
    RETURNS TABLE (id OID, name TEXT, path OID[], plain_name NAME)
AS $$
    SELECT * FROM granted_roles_pretty(current_user) ORDER BY PATH;
$$ LANGUAGE SQL;