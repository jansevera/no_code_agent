-- EV quartet deck: 32 cards, 8 sets (A-H) of 4.
-- Runs automatically the first time the Postgres container starts
-- (files in /docker-entrypoint-initdb.d). Data: cars.json from ev-database.org.

CREATE TABLE cards (
    card_id        varchar(2)   PRIMARY KEY,          -- e.g. 'A1'
    set_letter     char(1)      NOT NULL,             -- 'A'..'H'
    set_theme      text         NOT NULL,             -- e.g. 'Sedans'
    car_name       text         NOT NULL,             -- e.g. 'Škoda Enyaq'
    car_name_ascii text         NOT NULL,             -- same without accents: 'Skoda Enyaq'
    car_version    text         NOT NULL DEFAULT '',
    range_km       integer      NOT NULL,             -- WLTP range, higher wins
    acc_0_100_s    numeric(4,1) NOT NULL,             -- 0-100 km/h in seconds, LOWER wins
    top_speed_kmh  integer      NOT NULL,             -- higher wins
    battery_kwh    numeric(5,1) NOT NULL,             -- usable battery, higher wins
    -- calculated: battery / range * 100, LOWER wins
    consumption_kwh_100km numeric(5,2)
        GENERATED ALWAYS AS (round(battery_kwh / range_km * 100, 2)) STORED
);

COMMENT ON TABLE cards IS 'EV quartet cards. Higher wins except acc_0_100_s and consumption_kwh_100km (lower wins).';

INSERT INTO cards (card_id, set_letter, set_theme, car_name, car_name_ascii, car_version,
                   range_km, acc_0_100_s, top_speed_kmh, battery_kwh) VALUES
  ('A1', 'A', 'Sedans', 'Tesla Model 3', 'Tesla Model 3', 'Premium AWD (Highland)', 660, 4.4, 201, 79),
  ('A2', 'A', 'Sedans', 'BMW i4', 'BMW i4', 'eDrive40 (2025)', 613, 5.6, 190, 81.3),
  ('A3', 'A', 'Sedans', 'Hyundai IONIQ 6', 'Hyundai IONIQ 6', '84 kWh RWD (MY26)', 680, 7.4, 185, 80),
  ('A4', 'A', 'Sedans', 'Polestar 2', 'Polestar 2', 'Long Range Single Motor (MY26)', 659, 6.2, 205, 79),
  ('B1', 'B', 'Family SUVs', 'Tesla Model Y', 'Tesla Model Y', 'Premium AWD (Juniper)', 629, 4.8, 201, 79),
  ('B2', 'B', 'Family SUVs', 'Škoda Enyaq', 'Skoda Enyaq', '85 (MY25)', 586, 6.7, 180, 77),
  ('B3', 'B', 'Family SUVs', 'Kia EV6', 'Kia EV6', 'Long Range AWD (MY25)', 546, 5.2, 188, 80),
  ('B4', 'B', 'Family SUVs', 'Kia EV5', 'Kia EV5', '81.4 kWh (MY26)', 530, 8.4, 165, 78),
  ('C1', 'C', 'City cars', 'Renault 5 E-Tech', 'Renault 5 E-Tech', '52 kWh 150 hp', 416, 8, 150, 52),
  ('C2', 'C', 'City cars', 'Fiat 500e', 'Fiat 500e', 'Hatchback 42 kWh', 334, 9, 150, 37.3),
  ('C3', 'C', 'City cars', 'Hyundai INSTER', 'Hyundai INSTER', 'Long Range', 370, 10.6, 150, 46),
  ('C4', 'C', 'City cars', 'Citroën ë-C3', 'Citroen e-C3', '44 kWh', 327, 11.5, 132, 43.8),
  ('D1', 'D', 'Luxury', 'Mercedes-Benz EQS', 'Mercedes-Benz EQS', '450+', 822, 6.2, 210, 118),
  ('D2', 'D', 'Luxury', 'BMW i7', 'BMW i7', 'eDrive50', 611, 5.5, 205, 101.7),
  ('D3', 'D', 'Luxury', 'Lucid Air', 'Lucid Air', 'Grand Touring (MY25-26)', 961, 3.2, 270, 117),
  ('D4', 'D', 'Luxury', 'Audi A6 Sportback e-tron', 'Audi A6 Sportback e-tron', 'quattro', 720, 4.7, 210, 94.9),
  ('E1', 'E', 'Big SUVs', 'Kia EV9', 'Kia EV9', '99.8 kWh AWD', 523, 6, 200, 96),
  ('E2', 'E', 'Big SUVs', 'Volvo EX90', 'Volvo EX90', 'Twin Motor (MY26-27)', 624, 5.5, 180, 102),
  ('E3', 'E', 'Big SUVs', 'BMW iX', 'BMW iX', 'xDrive60', 701, 4.6, 200, 109.1),
  ('E4', 'E', 'Big SUVs', 'Audi Q6 e-tron', 'Audi Q6 e-tron', 'SUV quattro (MY26)', 642, 5.1, 210, 94.9),
  ('F1', 'F', 'Made in China', 'BYD SEAL', 'BYD SEAL', '82.5 kWh AWD Excellence', 520, 3.8, 180, 82.5),
  ('F2', 'F', 'Made in China', 'MG4 Electric', 'MG4 Electric', '77 kWh', 565, 6.5, 180, 74.4),
  ('F3', 'F', 'Made in China', 'XPENG G6', 'XPENG G6', 'RWD Long Range (MY25)', 525, 6.7, 202, 80),
  ('F4', 'F', 'Made in China', 'Zeekr 7X', 'Zeekr 7X', 'Long Range RWD', 615, 6, 210, 97),
  ('G1', 'G', 'Supercars', 'Tesla Model S', 'Tesla Model S', 'Plaid', 611, 2.4, 262, 95),
  ('G2', 'G', 'Supercars', 'Porsche Taycan', 'Porsche Taycan', 'Turbo S', 634, 2.4, 260, 97),
  ('G3', 'G', 'Supercars', 'Audi RS e-tron GT', 'Audi RS e-tron GT', 'performance', 592, 2.5, 250, 97),
  ('G4', 'G', 'Supercars', 'Hyundai IONIQ 5 N', 'Hyundai IONIQ 5 N', '', 448, 3.4, 260, 80),
  ('H1', 'H', 'Compact crossovers', 'Kia EV3', 'Kia EV3', 'Long Range', 605, 7.7, 170, 78),
  ('H2', 'H', 'Compact crossovers', 'Volvo EX30', 'Volvo EX30', 'Single Motor Extended Range', 476, 5.3, 180, 65),
  ('H3', 'H', 'Compact crossovers', 'Renault Scenic E-Tech', 'Renault Scenic E-Tech', '87 kWh 220 hp', 623, 7.9, 170, 87),
  ('H4', 'H', 'Compact crossovers', 'Škoda Elroq', 'Skoda Elroq', '85 (MY27)', 577, 6.6, 180, 77);

-- Read-only user for the agent's SQL tool: the LLM writes the SQL itself,
-- so it must not be able to change or delete anything.
CREATE ROLE quartet_reader LOGIN PASSWORD 'reader';
GRANT CONNECT ON DATABASE quartet TO quartet_reader;
GRANT USAGE ON SCHEMA public TO quartet_reader;
GRANT SELECT ON cards TO quartet_reader;
ALTER ROLE quartet_reader SET default_transaction_read_only = on;
ALTER ROLE quartet_reader SET statement_timeout = '5s';
