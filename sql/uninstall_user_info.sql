/*
 * Author: The maintainer's name
 * Created at: Sat Sep 29 16:34:48 +0200 2012
 *
 */

--
-- This is a example code genereted automaticaly
-- by pgxn-utils.

SET client_min_messages = warning;

BEGIN;

-- You can use this statements as
-- template for your extension.

DROP OPERATOR #? (text, text);
DROP FUNCTION user_info(text, text);
DROP TYPE user_info CASCADE;
COMMIT;
