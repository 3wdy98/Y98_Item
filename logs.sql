CREATE TABLE IF NOT EXISTS admin_item_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_name VARCHAR(100),
    target_id INT,
    item_name VARCHAR(100),
    amount INT,
    reason TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
