
local sql_docs = {
        -- ===== AGGREGATE FUNCTIONS =====
        ['COUNT'] = {
          syntax = 'COUNT(*) | COUNT(column) | COUNT(DISTINCT column)',
          description = 'Returns the number of rows or non-null values',
          examples = {
            'SELECT COUNT(*) FROM users;',
            'SELECT COUNT(DISTINCT city) FROM users;',
            'SELECT department, COUNT(*) FROM employees GROUP BY department;'
          },
          category = 'aggregate'
        },
        ['SUM'] = {
          syntax = 'SUM(column)',
          description = 'Returns the sum of numeric values',
          examples = {
            'SELECT SUM(salary) FROM employees;',
            'SELECT department, SUM(salary) FROM employees GROUP BY department;'
          },
          category = 'aggregate'
        },
        ['AVG'] = {
          syntax = 'AVG(column)',
          description = 'Returns the average of numeric values',
          examples = {
            'SELECT AVG(age) FROM users;',
            'SELECT department, AVG(salary) FROM employees GROUP BY department;'
          },
          category = 'aggregate'
        },
        ['MAX'] = {
          syntax = 'MAX(column)',
          description = 'Returns the maximum value',
          examples = {
            'SELECT MAX(salary) FROM employees;',
            'SELECT department, MAX(salary) FROM employees GROUP BY department;'
          },
          category = 'aggregate'
        },
        ['MIN'] = {
          syntax = 'MIN(column)',
          description = 'Returns the minimum value',
          examples = {
            'SELECT MIN(created_at) FROM orders;',
            'SELECT category, MIN(price) FROM products GROUP BY category;'
          },
          category = 'aggregate'
        },
        ['GROUP_CONCAT'] = {
          syntax = 'GROUP_CONCAT(column [SEPARATOR string])',
          description = 'Concatenates values from multiple rows (MySQL/SQLite)',
          examples = {
            "GROUP_CONCAT(name SEPARATOR ', ')",
            'SELECT department, GROUP_CONCAT(name) FROM employees GROUP BY department;'
          },
          category = 'aggregate'
        },
        ['STRING_AGG'] = {
          syntax = 'STRING_AGG(expression, delimiter [ORDER BY ...])',
          description = 'PostgreSQL: Concatenates values with delimiter',
          examples = {
            "STRING_AGG(name, ', ' ORDER BY name)",
            "SELECT department, STRING_AGG(name, ', ') FROM employees GROUP BY department;"
          },
          category = 'aggregate'
        },
        ['ARRAY_AGG'] = {
          syntax = 'ARRAY_AGG(expression [ORDER BY ...])',
          description = 'PostgreSQL: Aggregates values into an array',
          examples = {
            'ARRAY_AGG(id ORDER BY created_at)',
            'SELECT user_id, ARRAY_AGG(tag) FROM user_tags GROUP BY user_id;'
          },
          category = 'aggregate'
        },
        
        -- ===== STRING FUNCTIONS =====
        ['LENGTH'] = {
          syntax = 'LENGTH(string) | LEN(string)',
          description = 'Returns the character length of string',
          examples = {
            'SELECT LENGTH(name) FROM users;',
            "WHERE LENGTH(password) < 8"
          },
          category = 'string'
        },
        ['UPPER'] = {
          syntax = 'UPPER(string) | UCASE(string)',
          description = 'Converts string to uppercase',
          examples = {
            'SELECT UPPER(name) FROM users;',
            "WHERE UPPER(email) LIKE '%@GMAIL.COM'"
          },
          category = 'string'
        },
        ['LOWER'] = {
          syntax = 'LOWER(string) | LCASE(string)',
          description = 'Converts string to lowercase',
          examples = {
            'SELECT LOWER(email) FROM users;',
            "WHERE LOWER(status) = 'active'"
          },
          category = 'string'
        },
        ['TRIM'] = {
          syntax = 'TRIM([BOTH|LEADING|TRAILING] [remstr] FROM string)',
          description = 'Removes whitespace or specified characters',
          examples = {
            'TRIM(name)',
            "TRIM(LEADING '0' FROM zip_code)",
            'TRIM(BOTH \' \' FROM address)'
          },
          category = 'string'
        },
        ['LTRIM'] = {
          syntax = 'LTRIM(string [, characters])',
          description = 'Removes leading whitespace or specified characters',
          examples = {
            'LTRIM(name)',
            "LTRIM(phone, '+')"
          },
          category = 'string'
        },
        ['RTRIM'] = {
          syntax = 'RTRIM(string [, characters])',
          description = 'Removes trailing whitespace or specified characters',
          examples = {
            'RTRIM(name)',
            "RTRIM(price, '0')"
          },
          category = 'string'
        },
        ['SUBSTRING'] = {
          syntax = 'SUBSTRING(string FROM start [FOR length]) | SUBSTR(string, start, length)',
          description = 'Extracts substring from string',
          examples = {
            'SUBSTRING(name FROM 1 FOR 3)',
            'SUBSTR(phone, 1, 3)',
            'SUBSTRING(email FROM POSITION(\'@\' IN email))'
          },
          category = 'string'
        },
        ['CONCAT'] = {
          syntax = 'CONCAT(str1, str2, ...) | str1 || str2',
          description = 'Concatenates strings',
          examples = {
            "CONCAT(first_name, ' ', last_name)",
            "first_name || ' ' || last_name",
            'CONCAT(\'ID: \', CAST(id AS VARCHAR))'
          },
          category = 'string'
        },
        ['REPLACE'] = {
          syntax = 'REPLACE(string, from_str, to_str)',
          description = 'Replaces occurrences in string',
          examples = {
            "REPLACE(phone, '-', '')",
            "REPLACE(description, 'old', 'new')",
            "UPDATE products SET name = REPLACE(name, 'v1', 'v2');"
          },
          category = 'string'
        },
        ['POSITION'] = {
          syntax = 'POSITION(substring IN string) | CHARINDEX(substring, string)',
          description = 'Returns position of substring',
          examples = {
            "POSITION('@' IN email)",
            "WHERE POSITION('.com' IN email) > 0",
            "CHARINDEX(':', time_string)"
          },
          category = 'string'
        },
        ['LEFT'] = {
          syntax = 'LEFT(string, length)',
          description = 'Returns leftmost characters',
          examples = {
            'LEFT(zip_code, 3)',
            'SELECT LEFT(name, 1) as initial FROM users;'
          },
          category = 'string'
        },
        ['RIGHT'] = {
          syntax = 'RIGHT(string, length)',
          description = 'Returns rightmost characters',
          examples = {
            'RIGHT(phone, 4)',
            'SELECT RIGHT(account_number, 4) as last_digits;'
          },
          category = 'string'
        },
        ['SPLIT_PART'] = {
          syntax = 'SPLIT_PART(string, delimiter, field)',
          description = 'PostgreSQL: Split string and return specified field',
          examples = {
            "SPLIT_PART(email, '@', 2) as domain",
            "SPLIT_PART(full_path, '/', -1) as filename"
          },
          category = 'string'
        },
        ['REGEXP_REPLACE'] = {
          syntax = 'REGEXP_REPLACE(source, pattern, replacement [, flags])',
          description = 'Replace using regular expressions',
          examples = {
            "REGEXP_REPLACE(phone, '[^0-9]', '')",
            "REGEXP_REPLACE(text, '\\s+', ' ', 'g')"
          },
          category = 'string'
        },
        
        -- ===== DATE/TIME FUNCTIONS =====
        ['NOW'] = {
          syntax = 'NOW() | CURRENT_TIMESTAMP | GETDATE()',
          description = 'Returns current date and time',
          examples = {
            'SELECT NOW();',
            'INSERT INTO logs (created_at) VALUES (NOW());',
            'WHERE created_at < NOW() - INTERVAL \'1 day\''
          },
          category = 'datetime'
        },
        ['CURRENT_DATE'] = {
          syntax = 'CURRENT_DATE | CURDATE()',
          description = 'Returns current date',
          examples = {
            'SELECT CURRENT_DATE;',
            'WHERE birth_date < CURRENT_DATE - INTERVAL \'18 years\''
          },
          category = 'datetime'
        },
        ['CURRENT_TIME'] = {
          syntax = 'CURRENT_TIME | CURTIME()',
          description = 'Returns current time',
          examples = {
            'SELECT CURRENT_TIME;',
            'WHERE shop_open_time < CURRENT_TIME'
          },
          category = 'datetime'
        },
        ['DATE'] = {
          syntax = 'DATE(timestamp)',
          description = 'Extracts date part from timestamp',
          examples = {
            'SELECT DATE(created_at) FROM orders;',
            'GROUP BY DATE(created_at)'
          },
          category = 'datetime'
        },
        ['EXTRACT'] = {
          syntax = 'EXTRACT(field FROM timestamp)',
          description = 'Extract date/time field (YEAR, MONTH, DAY, HOUR, etc.)',
          examples = {
            'EXTRACT(YEAR FROM created_at)',
            'EXTRACT(MONTH FROM birth_date)',
            'EXTRACT(DOW FROM date) -- day of week',
            'WHERE EXTRACT(HOUR FROM created_at) BETWEEN 9 AND 17'
          },
          category = 'datetime'
        },
        ['DATE_TRUNC'] = {
          syntax = 'DATE_TRUNC(precision, timestamp)',
          description = 'PostgreSQL: Truncate to specified precision',
          examples = {
            "DATE_TRUNC('month', created_at)",
            "DATE_TRUNC('hour', timestamp)",
            "GROUP BY DATE_TRUNC('week', order_date)"
          },
          category = 'datetime'
        },
        ['DATEADD'] = {
          syntax = 'DATEADD(interval, number, date) | date + INTERVAL',
          description = 'Add interval to date',
          examples = {
            "DATEADD(day, 7, CURRENT_DATE)",
            "created_at + INTERVAL '1 month'",
            "NOW() - INTERVAL '30 days'"
          },
          category = 'datetime'
        },
        ['DATEDIFF'] = {
          syntax = 'DATEDIFF(date1, date2) | AGE(timestamp1, timestamp2)',
          description = 'Difference between dates',
          examples = {
            'DATEDIFF(end_date, start_date)',
            'AGE(NOW(), birth_date)',
            'EXTRACT(EPOCH FROM (end_time - start_time))/3600 as hours'
          },
          category = 'datetime'
        },
        ['TO_CHAR'] = {
          syntax = 'TO_CHAR(value, format)',
          description = 'PostgreSQL: Convert to string with format',
          examples = {
            "TO_CHAR(created_at, 'YYYY-MM-DD')",
            "TO_CHAR(price, '$999,999.99')",
            "TO_CHAR(timestamp, 'Day, Month DD, YYYY')"
          },
          category = 'datetime'
        },
        ['TO_DATE'] = {
          syntax = 'TO_DATE(string, format)',
          description = 'Convert string to date',
          examples = {
            "TO_DATE('2024-01-15', 'YYYY-MM-DD')",
            "TO_DATE('15/01/2024', 'DD/MM/YYYY')"
          },
          category = 'datetime'
        },
        
        -- ===== CONDITIONAL FUNCTIONS =====
        ['CASE'] = {
          syntax = 'CASE WHEN condition THEN result [WHEN ...] [ELSE default] END',
          description = 'Conditional expression',
          examples = {
            [[CASE 
                WHEN age < 18 THEN 'Minor'
                WHEN age < 65 THEN 'Adult'
                ELSE 'Senior'
              END as age_group]],
            [[CASE status
                WHEN 'active' THEN 1
                WHEN 'pending' THEN 0.5
                ELSE 0
              END as weight]]
          },
          category = 'conditional'
        },
        ['COALESCE'] = {
          syntax = 'COALESCE(val1, val2, ...)',
          description = 'Returns first non-null value',
          examples = {
            "COALESCE(nickname, first_name, 'Guest')",
            'COALESCE(mobile, home_phone, work_phone) as contact',
            'COALESCE(SUM(amount), 0) as total'
          },
          category = 'conditional'
        },
        ['NULLIF'] = {
          syntax = 'NULLIF(val1, val2)',
          description = 'Returns NULL if values are equal',
          examples = {
            "NULLIF(status, '')",
            'NULLIF(total, 0)',
            'AVG(NULLIF(score, 0)) -- exclude zeros from average'
          },
          category = 'conditional'
        },
        ['IFNULL'] = {
          syntax = 'IFNULL(val1, val2) | ISNULL(val1, val2)',
          description = 'Returns val2 if val1 is NULL',
          examples = {
            "IFNULL(description, 'No description')",
            'IFNULL(discount, 0)',
            'ISNULL(deleted_at, \'9999-12-31\')'
          },
          category = 'conditional'
        },
        ['GREATEST'] = {
          syntax = 'GREATEST(val1, val2, ...)',
          description = 'Returns the greatest value',
          examples = {
            'GREATEST(10, 20, 30)',
            'GREATEST(start_date, MIN_DATE)',
            'SELECT GREATEST(price1, price2, price3) as max_price'
          },
          category = 'conditional'
        },
        ['LEAST'] = {
          syntax = 'LEAST(val1, val2, ...)',
          description = 'Returns the smallest value',
          examples = {
            'LEAST(10, 20, 30)',
            'LEAST(end_date, MAX_DATE)',
            'SELECT LEAST(cost1, cost2, cost3) as min_cost'
          },
          category = 'conditional'
        },
        
        -- ===== CONVERSION FUNCTIONS =====
        ['CAST'] = {
          syntax = 'CAST(expression AS datatype)',
          description = 'Convert expression to specified data type',
          examples = {
            'CAST(id AS VARCHAR)',
            'CAST(\'123\' AS INTEGER)',
            'CAST(created_at AS DATE)',
            'CAST(price AS DECIMAL(10,2))'
          },
          category = 'conversion'
        },
        ['CONVERT'] = {
          syntax = 'CONVERT(datatype, expression [, style])',
          description = 'Convert expression to data type (SQL Server/MySQL)',
          examples = {
            'CONVERT(VARCHAR, id)',
            'CONVERT(DATE, \'2024-01-15\')',
            'CONVERT(DECIMAL(10,2), price)'
          },
          category = 'conversion'
        },
        
        -- ===== WINDOW FUNCTIONS =====
        ['ROW_NUMBER'] = {
          syntax = 'ROW_NUMBER() OVER (ORDER BY column)',
          description = 'Assigns unique row numbers',
          examples = {
            'ROW_NUMBER() OVER (ORDER BY created_at DESC)',
            'ROW_NUMBER() OVER (PARTITION BY category ORDER BY price)',
            [[SELECT *, ROW_NUMBER() OVER (ORDER BY score DESC) as rank
              FROM players]]
          },
          category = 'window'
        },
        ['RANK'] = {
          syntax = 'RANK() OVER (ORDER BY column)',
          description = 'Assigns ranks with gaps for ties',
          examples = {
            'RANK() OVER (ORDER BY score DESC)',
            'RANK() OVER (PARTITION BY department ORDER BY salary DESC)',
            'SELECT name, RANK() OVER (ORDER BY sales DESC) as sales_rank'
          },
          category = 'window'
        },
        ['DENSE_RANK'] = {
          syntax = 'DENSE_RANK() OVER (ORDER BY column)',
          description = 'Assigns ranks without gaps',
          examples = {
            'DENSE_RANK() OVER (ORDER BY score DESC)',
            'DENSE_RANK() OVER (PARTITION BY category ORDER BY rating DESC)'
          },
          category = 'window'
        },
        ['LAG'] = {
          syntax = 'LAG(column, offset, default) OVER (ORDER BY ...)',
          description = 'Access previous row value',
          examples = {
            'LAG(price, 1) OVER (ORDER BY date)',
            'LAG(value, 1, 0) OVER (PARTITION BY user_id ORDER BY date)',
            'price - LAG(price, 1) OVER (ORDER BY date) as price_change'
          },
          category = 'window'
        },
        ['LEAD'] = {
          syntax = 'LEAD(column, offset, default) OVER (ORDER BY ...)',
          description = 'Access next row value',
          examples = {
            'LEAD(price, 1) OVER (ORDER BY date)',
            'LEAD(event_time, 1) OVER (PARTITION BY user_id ORDER BY event_time)'
          },
          category = 'window'
        },
        ['FIRST_VALUE'] = {
          syntax = 'FIRST_VALUE(column) OVER (ORDER BY ... ROWS/RANGE ...)',
          description = 'Returns first value in window',
          examples = {
            'FIRST_VALUE(price) OVER (PARTITION BY product_id ORDER BY date)',
            'FIRST_VALUE(score) OVER (ORDER BY created_at ROWS UNBOUNDED PRECEDING)'
          },
          category = 'window'
        },
        ['LAST_VALUE'] = {
          syntax = 'LAST_VALUE(column) OVER (ORDER BY ... ROWS/RANGE ...)',
          description = 'Returns last value in window',
          examples = {
            'LAST_VALUE(price) OVER (PARTITION BY product_id ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)',
            'LAST_VALUE(status) OVER (PARTITION BY user_id ORDER BY updated_at)'
          },
          category = 'window'
        },
        ['NTILE'] = {
          syntax = 'NTILE(n) OVER (ORDER BY column)',
          description = 'Divides rows into n buckets',
          examples = {
            'NTILE(4) OVER (ORDER BY score) as quartile',
            'NTILE(10) OVER (ORDER BY revenue) as decile',
            'NTILE(100) OVER (ORDER BY amount) as percentile'
          },
          category = 'window'
        },
        
        -- ===== MATHEMATICAL FUNCTIONS =====
        ['ROUND'] = {
          syntax = 'ROUND(number, decimals)',
          description = 'Rounds number to specified decimals',
          examples = {
            'ROUND(price, 2)',
            'ROUND(AVG(score), 1)',
            'ROUND(total * 1.08, 2) as with_tax'
          },
          category = 'math'
        },
        ['CEIL'] = {
          syntax = 'CEIL(number) | CEILING(number)',
          description = 'Returns smallest integer >= number',
          examples = {
            'CEIL(4.3) -- returns 5',
            'CEILING(hours_worked / 8) as days_worked'
          },
          category = 'math'
        },
        ['FLOOR'] = {
          syntax = 'FLOOR(number)',
          description = 'Returns largest integer <= number',
          examples = {
            'FLOOR(4.7) -- returns 4',
            'FLOOR(age / 10) * 10 as age_group'
          },
          category = 'math'
        },
        ['ABS'] = {
          syntax = 'ABS(number)',
          description = 'Returns absolute value',
          examples = {
            'ABS(balance)',
            'ABS(actual - expected) as variance'
          },
          category = 'math'
        },
        ['POWER'] = {
          syntax = 'POWER(base, exponent) | POW(base, exponent)',
          description = 'Returns base raised to exponent',
          examples = {
            'POWER(2, 3) -- returns 8',
            'POWER(1.05, years) as compound_interest'
          },
          category = 'math'
        },
        ['SQRT'] = {
          syntax = 'SQRT(number)',
          description = 'Returns square root',
          examples = {
            'SQRT(16) -- returns 4',
            'SQRT(POWER(x2-x1, 2) + POWER(y2-y1, 2)) as distance'
          },
          category = 'math'
        },
        ['MOD'] = {
          syntax = 'MOD(n, m) | n % m',
          description = 'Returns remainder of n/m',
          examples = {
            'MOD(10, 3) -- returns 1',
            'WHERE MOD(id, 2) = 0 -- even IDs only',
            'id % 10 as last_digit'
          },
          category = 'math'
        },
        ['RANDOM'] = {
          syntax = 'RANDOM() | RAND()',
          description = 'Returns random number between 0 and 1',
          examples = {
            'ORDER BY RANDOM() LIMIT 10',
            'FLOOR(RANDOM() * 100) as random_percent',
            'WHERE RANDOM() < 0.1 -- 10% sample'
          },
          category = 'math'
        },
        
        -- ===== JSON FUNCTIONS (PostgreSQL) =====
        ['JSON_EXTRACT'] = {
          syntax = 'json_column->\'key\' | json_column->>\'key\' | JSON_EXTRACT(json, path)',
          description = 'Extract value from JSON',
          examples = {
            "data->>'name' as name",
            "settings->'preferences'->>'theme'",
            "JSON_EXTRACT(data, '$.address.city')"
          },
          category = 'json'
        },
        ['JSON_ARRAY_LENGTH'] = {
          syntax = 'JSON_ARRAY_LENGTH(json_array)',
          description = 'Returns length of JSON array',
          examples = {
            "JSON_ARRAY_LENGTH(tags)",
            "WHERE JSON_ARRAY_LENGTH(items) > 0"
          },
          category = 'json'
        },
        ['JSONB_SET'] = {
          syntax = 'JSONB_SET(target, path, new_value)',
          description = 'PostgreSQL: Set value in JSONB',
          examples = {
            "JSONB_SET(data, '{address,city}', '\"New York\"')",
            "UPDATE users SET profile = JSONB_SET(profile, '{age}', '25');"
          },
          category = 'json'
        },
        
        -- ===== CLAUSES AND KEYWORDS =====
        ['SELECT'] = {
          syntax = 'SELECT [DISTINCT] columns FROM table [WHERE ...] [GROUP BY ...] [ORDER BY ...]',
          description = 'Retrieve data from tables',
          examples = {
            'SELECT * FROM users;',
            'SELECT DISTINCT city FROM addresses;',
            'SELECT id, name, email FROM users WHERE active = true;',
            [[SELECT 
                department, 
                COUNT(*) as employee_count,
                AVG(salary) as avg_salary
              FROM employees
              GROUP BY department
              ORDER BY avg_salary DESC;]]
          },
          category = 'clause'
        },
        ['FROM'] = {
          syntax = 'FROM table [alias] [JOIN ...]',
          description = 'Specify source table(s)',
          examples = {
            'FROM users',
            'FROM users u',
            'FROM users u JOIN orders o ON u.id = o.user_id'
          },
          category = 'clause'
        },
        ['WHERE'] = {
          syntax = 'WHERE condition [AND|OR condition ...]',
          description = 'Filter rows based on conditions',
          examples = {
            'WHERE age >= 18',
            'WHERE status = \'active\' AND created_at > \'2024-01-01\'',
            'WHERE email LIKE \'%@gmail.com\'',
            'WHERE id IN (1, 2, 3)',
            'WHERE price BETWEEN 10 AND 100'
          },
          category = 'clause'
        },
        ['GROUP'] = {
          syntax = 'GROUP BY column [, column ...] [HAVING condition]',
          description = 'Group rows for aggregate functions',
          examples = {
            'GROUP BY department',
            'GROUP BY EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at)',
            'GROUP BY category HAVING COUNT(*) > 5'
          },
          category = 'clause'
        },
        ['HAVING'] = {
          syntax = 'HAVING condition',
          description = 'Filter groups (used after GROUP BY)',
          examples = {
            'GROUP BY department HAVING AVG(salary) > 50000',
            'GROUP BY user_id HAVING COUNT(*) >= 3',
            'GROUP BY DATE(created_at) HAVING SUM(amount) > 1000'
          },
          category = 'clause'
        },
        ['ORDER'] = {
          syntax = 'ORDER BY column [ASC|DESC] [, column [ASC|DESC] ...]',
          description = 'Sort result set',
          examples = {
            'ORDER BY created_at DESC',
            'ORDER BY last_name, first_name',
            'ORDER BY CASE WHEN priority = \'high\' THEN 1 ELSE 2 END, created_at'
          },
          category = 'clause'
        },
        ['LIMIT'] = {
          syntax = 'LIMIT n [OFFSET m]',
          description = 'Restrict number of returned rows',
          examples = {
            'LIMIT 10',
            'LIMIT 10 OFFSET 20',
            'LIMIT 1 -- Get single row'
          },
          category = 'clause'
        },
        ['JOIN'] = {
          syntax = 'JOIN table ON condition | INNER JOIN | LEFT JOIN | RIGHT JOIN | FULL JOIN',
          description = 'Combine rows from multiple tables',
          examples = {
            'JOIN orders ON users.id = orders.user_id',
            'LEFT JOIN addresses ON users.id = addresses.user_id',
            'INNER JOIN products p ON order_items.product_id = p.id',
            [[FROM users u
              LEFT JOIN orders o ON u.id = o.user_id
              LEFT JOIN addresses a ON u.id = a.user_id]]
          },
          category = 'clause'
        },
        ['UNION'] = {
          syntax = 'query1 UNION [ALL] query2',
          description = 'Combine result sets (removes duplicates unless ALL is used)',
          examples = {
            'SELECT name FROM users UNION SELECT name FROM customers',
            'SELECT id, name FROM table1 UNION ALL SELECT id, name FROM table2'
          },
          category = 'clause'
        },
        ['WITH'] = {
          syntax = 'WITH cte_name AS (query) SELECT ... FROM cte_name',
          description = 'Common Table Expression - define temporary result set',
          examples = {
            [[WITH recent_orders AS (
                SELECT * FROM orders 
                WHERE created_at > NOW() - INTERVAL '30 days'
              )
              SELECT * FROM recent_orders WHERE amount > 100;]],
            [[WITH RECURSIVE numbers AS (
                SELECT 1 as n
                UNION ALL
                SELECT n + 1 FROM numbers WHERE n < 10
              )
              SELECT * FROM numbers;]]
          },
          category = 'clause'
        },
        ['INSERT'] = {
          syntax = 'INSERT INTO table (columns) VALUES (values) | INSERT INTO table SELECT ...',
          description = 'Add new rows to table',
          examples = {
            "INSERT INTO users (name, email) VALUES ('John', 'john@email.com');",
            'INSERT INTO users (name, email) VALUES (?, ?);',
            [[INSERT INTO archive_orders 
              SELECT * FROM orders WHERE created_at < '2023-01-01';]],
            "INSERT INTO products (name, price) VALUES ('Widget', 9.99) RETURNING id;"
          },
          category = 'dml'
        },
        ['UPDATE'] = {
          syntax = 'UPDATE table SET column = value [, ...] WHERE condition',
          description = 'Modify existing rows',
          examples = {
            "UPDATE users SET status = 'active' WHERE id = 1;",
            'UPDATE products SET price = price * 1.1 WHERE category = \'electronics\';',
            [[UPDATE orders o 
              SET total = (
                SELECT SUM(quantity * price) 
                FROM order_items 
                WHERE order_id = o.id
              );]]
          },
          category = 'dml'
        },
        ['DELETE'] = {
          syntax = 'DELETE FROM table WHERE condition',
          description = 'Remove rows from table',
          examples = {
            'DELETE FROM logs WHERE created_at < NOW() - INTERVAL \'90 days\';',
            'DELETE FROM users WHERE id = 1;',
            [[DELETE FROM orders 
              WHERE id IN (
                SELECT id FROM orders 
                WHERE status = 'cancelled' 
                AND created_at < '2023-01-01'
              );]]
          },
          category = 'dml'
        },
        ['CREATE'] = {
          syntax = 'CREATE TABLE table (column datatype constraints, ...)',
          description = 'Create new table',
          examples = {
            [[CREATE TABLE users (
                id SERIAL PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                name VARCHAR(100),
                created_at TIMESTAMP DEFAULT NOW()
              );]],
            [[CREATE INDEX idx_users_email ON users(email);]],
            [[CREATE VIEW active_users AS 
              SELECT * FROM users WHERE status = 'active';]]
          },
          category = 'ddl'
        },
        ['ALTER'] = {
          syntax = 'ALTER TABLE table ADD|DROP|MODIFY column',
          description = 'Modify table structure',
          examples = {
            'ALTER TABLE users ADD COLUMN phone VARCHAR(20);',
            'ALTER TABLE users DROP COLUMN old_field;',
            'ALTER TABLE users ALTER COLUMN age TYPE INTEGER;',
            'ALTER TABLE orders ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id);'
          },
          category = 'ddl'
        },
        ['DROP'] = {
          syntax = 'DROP TABLE|INDEX|VIEW [IF EXISTS] name',
          description = 'Delete database object',
          examples = {
            'DROP TABLE IF EXISTS temp_data;',
            'DROP INDEX idx_users_email;',
            'DROP VIEW user_summary CASCADE;'
          },
          category = 'ddl'
        },
        ['DISTINCT'] = {
          syntax = 'SELECT DISTINCT column FROM table',
          description = 'Return unique values only',
          examples = {
            'SELECT DISTINCT category FROM products;',
            'SELECT DISTINCT ON (user_id) * FROM orders ORDER BY user_id, created_at DESC;',
            'SELECT COUNT(DISTINCT user_id) FROM orders;'
          },
          category = 'modifier'
        },
        ['EXISTS'] = {
          syntax = 'WHERE EXISTS (subquery)',
          description = 'Test for existence of rows',
          examples = {
            [[WHERE EXISTS (
                SELECT 1 FROM orders WHERE orders.user_id = users.id
              )]],
            [[SELECT * FROM users u
              WHERE NOT EXISTS (
                SELECT 1 FROM blacklist WHERE email = u.email
              );]]
          },
          category = 'operator'
        },
        ['IN'] = {
          syntax = 'WHERE column IN (value1, value2, ...) | WHERE column IN (subquery)',
          description = 'Test if value is in list',
          examples = {
            "WHERE status IN ('active', 'pending', 'processing')",
            'WHERE id IN (SELECT user_id FROM orders WHERE total > 100)',
            'WHERE id NOT IN (1, 2, 3)'
          },
          category = 'operator'
        },
        ['BETWEEN'] = {
          syntax = 'WHERE column BETWEEN value1 AND value2',
          description = 'Test if value is within range',
          examples = {
            'WHERE age BETWEEN 18 AND 65',
            "WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31'",
            'WHERE price NOT BETWEEN 0 AND 100'
          },
          category = 'operator'
        },
        ['LIKE'] = {
          syntax = 'WHERE column LIKE pattern',
          description = 'Pattern matching (% = any chars, _ = single char)',
          examples = {
            "WHERE email LIKE '%@gmail.com'",
            "WHERE name LIKE 'John%'",
            "WHERE code LIKE 'A_B_'",
            "WHERE description ILIKE '%search%' -- case insensitive"
          },
          category = 'operator'
        },
        ['IS'] = {
          syntax = 'WHERE column IS NULL | IS NOT NULL',
          description = 'Test for NULL values',
          examples = {
            'WHERE deleted_at IS NULL',
            'WHERE phone IS NOT NULL',
            'WHERE archived IS TRUE',
            'WHERE validated IS NOT FALSE'
          },
          category = 'operator'
        },
        
        -- ===== CONSTRAINTS =====
        ['PRIMARY'] = {
          syntax = 'PRIMARY KEY (column)',
          description = 'Unique identifier for table rows',
          examples = {
            'id INTEGER PRIMARY KEY',
            'PRIMARY KEY (id)',
            'CONSTRAINT pk_users PRIMARY KEY (id)',
            'PRIMARY KEY (user_id, role_id) -- composite key'
          },
          category = 'constraint'
        },
        ['FOREIGN'] = {
          syntax = 'FOREIGN KEY (column) REFERENCES table(column)',
          description = 'Reference to primary key in another table',
          examples = {
            'user_id INTEGER REFERENCES users(id)',
            'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE',
            'CONSTRAINT fk_order_user FOREIGN KEY (user_id) REFERENCES users(id)'
          },
          category = 'constraint'
        },
        ['UNIQUE'] = {
          syntax = 'UNIQUE (column)',
          description = 'Ensure column values are unique',
          examples = {
            'email VARCHAR(255) UNIQUE',
            'UNIQUE (email)',
            'CONSTRAINT uk_user_email UNIQUE (email)',
            'UNIQUE (user_id, role_id) -- composite unique'
          },
          category = 'constraint'
        },
        ['CHECK'] = {
          syntax = 'CHECK (condition)',
          description = 'Validate column values',
          examples = {
            'age INTEGER CHECK (age >= 0)',
            'CHECK (price > 0)',
            'CHECK (end_date > start_date)',
            "CONSTRAINT chk_status CHECK (status IN ('active', 'inactive', 'pending'))"
          },
          category = 'constraint'
        },
        ['DEFAULT'] = {
          syntax = 'DEFAULT value',
          description = 'Set default value for column',
          examples = {
            'created_at TIMESTAMP DEFAULT NOW()',
            'status VARCHAR(20) DEFAULT \'pending\'',
            'quantity INTEGER DEFAULT 1',
            'is_active BOOLEAN DEFAULT TRUE'
          },
          category = 'constraint'
        },
        
        -- ===== INDEXES =====
        ['INDEX'] = {
          syntax = 'CREATE [UNIQUE] INDEX name ON table (columns)',
          description = 'Improve query performance',
          examples = {
            'CREATE INDEX idx_users_email ON users(email);',
            'CREATE UNIQUE INDEX idx_users_username ON users(username);',
            'CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC);',
            'CREATE INDEX idx_products_name ON products USING GIN(to_tsvector(\'english\', name));'
          },
          category = 'index'
        },
        
        -- ===== TRANSACTIONS =====
        ['BEGIN'] = {
          syntax = 'BEGIN [TRANSACTION]',
          description = 'Start a transaction',
          examples = {
            'BEGIN;',
            'BEGIN TRANSACTION;',
            'BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;'
          },
          category = 'transaction'
        },
        ['COMMIT'] = {
          syntax = 'COMMIT [TRANSACTION]',
          description = 'Save transaction changes',
          examples = {
            'COMMIT;',
            'COMMIT TRANSACTION;'
          },
          category = 'transaction'
        },
        ['ROLLBACK'] = {
          syntax = 'ROLLBACK [TRANSACTION]',
          description = 'Undo transaction changes',
          examples = {
            'ROLLBACK;',
            'ROLLBACK TRANSACTION;',
            'ROLLBACK TO SAVEPOINT sp1;'
          },
          category = 'transaction'
        },
        
        -- ===== ADVANCED =====
        ['PARTITION'] = {
          syntax = 'PARTITION BY column',
          description = 'Divide result set for window functions',
          examples = {
            'ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC)',
            'SUM(amount) OVER (PARTITION BY user_id)',
            'RANK() OVER (PARTITION BY category ORDER BY price)'
          },
          category = 'advanced'
        },
        ['OVER'] = {
          syntax = 'function() OVER (window_specification)',
          description = 'Define window for window functions',
          examples = {
            'COUNT(*) OVER ()',
            'SUM(amount) OVER (ORDER BY date)',
            'AVG(score) OVER (PARTITION BY class ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)'
          },
          category = 'advanced'
        },
        ['LATERAL'] = {
          syntax = 'FROM table1, LATERAL (subquery)',
          description = 'PostgreSQL: Subquery can reference preceding tables',
          examples = {
            [[FROM users u, LATERAL (
                SELECT * FROM orders 
                WHERE user_id = u.id 
                ORDER BY created_at DESC 
                LIMIT 5
              ) recent_orders]]
          },
          category = 'advanced'
        },
        ['RETURNING'] = {
          syntax = 'INSERT/UPDATE/DELETE ... RETURNING columns',
          description = 'PostgreSQL: Return values from DML operations',
          examples = {
            'INSERT INTO users (name) VALUES (\'John\') RETURNING id;',
            'UPDATE products SET price = price * 1.1 RETURNING id, price;',
            'DELETE FROM logs WHERE old = true RETURNING COUNT(*);'
          },
          category = 'advanced'
        },
        ['UPSERT'] = {
          syntax = 'INSERT ... ON CONFLICT (column) DO UPDATE SET ...',
          description = 'PostgreSQL: Insert or update if exists',
          examples = {
            [[INSERT INTO users (email, name) 
              VALUES ('john@email.com', 'John')
              ON CONFLICT (email) 
              DO UPDATE SET name = EXCLUDED.name;]],
            [[INSERT INTO daily_stats (date, views) 
              VALUES (CURRENT_DATE, 1)
              ON CONFLICT (date) 
              DO UPDATE SET views = daily_stats.views + 1;]]
          },
          category = 'advanced'
        },
        ['EXPLAIN'] = {
          syntax = 'EXPLAIN [ANALYZE] query',
          description = 'Show execution plan',
          examples = {
            'EXPLAIN SELECT * FROM users WHERE email = \'john@email.com\';',
            'EXPLAIN ANALYZE SELECT * FROM orders WHERE created_at > \'2024-01-01\';',
            'EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM large_table;'
          },
          category = 'advanced'
        },
      }

return(sql_docs)
