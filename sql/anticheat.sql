CREATE TABLE anticheat_bans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(64) NOT NULL,
  reason TEXT NOT NULL,
  banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE anticheat_violations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(64) NOT NULL,
  violation_type VARCHAR(64) NOT NULL,
  description TEXT,
  severity INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
