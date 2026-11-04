CREATE TABLE countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE,
    is_banned BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE ip_addresses (
    client_ip  VARCHAR(45) PRIMARY KEY,
    country_id INT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

CREATE TABLE requests_3nf (
    id  INT AUTO_INCREMENT PRIMARY KEY,
    client_ip   VARCHAR(45) NOT NULL,
    gender      VARCHAR(16),
    age         VARCHAR(16),
    income      VARCHAR(32),
    time_of_day DATETIME,
    requested_file  VARCHAR(255),
    FOREIGN KEY (client_ip) REFERENCES ip_addresses(client_ip)
);

-- 0. Check if the data are legal (The results should be null)
SELECT client_ip FROM requests
GROUP BY client_ip HAVING COUNT(DISTINCT country) > 1;

SELECT country FROM requests
GROUP BY country HAVING COUNT(DISTINCT is_banned) > 1;

-- 1. countries
INSERT INTO countries (country_name, is_banned)
SELECT country, MAX(is_banned)
FROM requests
WHERE country is NOT NULL
GROUP BY country;

-- 2. ip_addresses
INSERT INTO ip_addresses (client_ip, country_id)
SELECT r.client_ip, MIN(c.country_id)
FROM requests r
JOIN countries c ON c.country_name = r.country
WHERE r.client_ip IS NOT NULL
GROUP BY r.client_ip;

-- 3. requests table in 3nf
INSERT INTO requests_3nf
    (id, client_ip, gender, age, income, time_of_day, requested_file)
SELECT r.id, r.client_ip, r.gender, r.age, r.income, r.time_of_day, r.requested_file
FROM requests r
JOIN ip_addresses i ON r.client_ip = i.client_ip;
