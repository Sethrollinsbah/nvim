local templates = {
              { name = "SELECT with JOIN", template = [[
SELECT 
    t1.column1,
    t1.column2,
    t2.column3
FROM table1 t1
JOIN table2 t2 ON t1.id = t2.table1_id
WHERE t1.status = 'active'
ORDER BY t1.created_at DESC
LIMIT 10;]] },
              { name = "INSERT with RETURNING", template = [[
INSERT INTO table_name (column1, column2, column3)
VALUES ($1, $2, $3)
RETURNING id;]] },
              { name = "UPDATE with JOIN", template = [[
UPDATE table1 t1
SET column1 = t2.value
FROM table2 t2
WHERE t1.id = t2.table1_id
    AND t1.status = 'pending';]] },
              { name = "Common Table Expression (CTE)", template = [[
WITH cte_name AS (
    SELECT 
        column1,
        column2
    FROM table_name
    WHERE condition
)
SELECT * FROM cte_name;]] },
              { name = "Window Function Example", template = [[
SELECT 
    id,
    name,
    score,
    ROW_NUMBER() OVER (ORDER BY score DESC) as rank,
    AVG(score) OVER (PARTITION BY category) as category_avg
FROM results;]] },
              { name = "Create Table with Constraints", template = [[
CREATE TABLE table_name (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);]] },
              { name = "Upsert (INSERT ON CONFLICT)", template = [[
INSERT INTO table_name (key_column, value_column)
VALUES ($1, $2)
ON CONFLICT (key_column) 
DO UPDATE SET 
    value_column = EXCLUDED.value_column,
    updated_at = NOW();]] },
              { name = "Recursive CTE", template = [[
WITH RECURSIVE hierarchy AS (
    -- Anchor member
    SELECT id, parent_id, name, 1 as level
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive member
    SELECT c.id, c.parent_id, c.name, h.level + 1
    FROM categories c
    JOIN hierarchy h ON c.parent_id = h.id
)
SELECT * FROM hierarchy ORDER BY level, name;]] },
            }

return(templates)
