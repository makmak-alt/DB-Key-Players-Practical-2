-- ============================================================================
-- CSC312 Practical Assignment 2
-- Escape Room Management System - Sample Data
-- Team: Key Players   Members: 4427029, [ADD TEAMMATES]
-- File: 02_data.sql  (run after 01_schema.sql)
-- ============================================================================

USE CSC312_DB;

-- Venue_Manager --------------------------------------------------------------
INSERT INTO Venue_Manager (manager_id, first_name, last_name, email, phone, hire_date, salary) VALUES
(1, 'Thandi',  'Nkosi',    't.nkosi@escapesa.co.za',  '0825550101', '2021-02-01', 38500.00),
(2, 'Pieter',  'van Wyk',  'p.vanwyk@escapesa.co.za', '0825550102', '2022-06-15', 36200.00),
(3, 'Ayesha',  'Parker',   'a.parker@escapesa.co.za', '0825550103', '2023-01-10', 39100.00);

-- Venue ----------------------------------------------------------------------
INSERT INTO Venue (venue_id, venue_name, street, city, manager_id, open_date) VALUES
(1, 'Enigma Cape Town',  '12 Loop Street',      'Cape Town', 1, '2021-04-01'),
(2, 'Lockdown Joburg',   '45 Fox Street',       'Johannesburg', 2, '2022-08-20'),
(3, 'Cipher Durban',     '7 Florida Road',      'Durban', 3, '2023-03-05');

-- Venue_Phone (multivalued attribute) ----------------------------------------
INSERT INTO Venue_Phone (venue_id, phone) VALUES
(1, '0215551001'), (1, '0215551002'),
(2, '0115552001'),
(3, '0315553001'), (3, '0315553002');

-- Room -----------------------------------------------------------------------
INSERT INTO Room (room_id, venue_id, room_name, theme, difficulty_level, min_players, max_players, price_per_session, room_status) VALUES
(1, 1, 'The Alchemist Lab',   'Science',    4, 2, 6, 950.00, 'Available'),
(2, 1, 'Pirate Cove',         'Adventure',  2, 2, 8, 750.00, 'Available'),
(3, 1, 'Asylum Ward 9',       'Horror',     5, 3, 6, 1100.00, 'Under Maintenance'),
(4, 2, 'Heist: Gold Reserve', 'Crime',      3, 2, 6, 890.00, 'Available'),
(5, 2, 'Space Station Zeta',  'Sci-Fi',     4, 2, 5, 990.00, 'Available'),
(6, 2, 'Pharaohs Tomb',       'History',    3, 2, 6, 820.00, 'Available'),
(7, 3, 'Krakens Revenge',     'Adventure',  3, 2, 8, 780.00, 'Available'),
(8, 3, 'The Dollhouse',       'Horror',     5, 2, 4, 1050.00, 'Available');

-- Game_Master ------------------------------------------------------------------
INSERT INTO Game_Master (gm_id, venue_id, first_name, last_name, email, hire_date, hourly_rate) VALUES
(1, 1, 'Sipho',   'Dlamini',  's.dlamini@escapesa.co.za',  '2021-05-03', 185.00),
(2, 1, 'Lerato',  'Mokoena',  'l.mokoena@escapesa.co.za',  '2022-02-14', 190.00),
(3, 2, 'Johan',   'Botha',    'j.botha@escapesa.co.za',    '2022-09-01', 180.00),
(4, 2, 'Naledi',  'Sithole',  'n.sithole@escapesa.co.za',  '2023-04-18', 195.00),
(5, 3, 'Kiran',   'Pillay',   'k.pillay@escapesa.co.za',   '2023-05-02', 175.00),
(6, 3, 'Emma',    'Bothma',   'e.bothma@escapesa.co.za',   '2024-01-22', 170.00);

-- Puzzle ----------------------------------------------------------------------
INSERT INTO Puzzle (puzzle_id, room_id, puzzle_name, puzzle_type, time_limit_minutes, is_active) VALUES
( 1, 1, 'Periodic Cipher',     'Cipher',   10, TRUE),
( 2, 1, 'Volatile Mixture',    'Physical', 12, TRUE),
( 3, 1, 'Formula Lock',        'Logic',     8, TRUE),
( 4, 2, 'Map of Stars',        'Logic',    10, TRUE),
( 5, 2, 'Captain’s Chest',     'Physical', 15, TRUE),
( 6, 3, 'Patient Records',     'Cipher',   12, TRUE),
( 7, 3, 'Electroshock Panel',  'Physical', 10, FALSE),
( 8, 4, 'Vault Combination',   'Logic',    12, TRUE),
( 9, 4, 'Laser Grid Bypass',   'Physical', 10, TRUE),
(10, 5, 'Oxygen Rebalance',    'Logic',    12, TRUE),
(11, 5, 'Alien Glyph Decoder', 'Cipher',   14, TRUE),
(12, 6, 'Hieroglyph Wall',     'Cipher',   12, TRUE),
(13, 7, 'Ship Rigging Knots',  'Physical', 10, TRUE),
(14, 8, 'Porcelain Tea Party', 'Logic',    10, TRUE);

-- Clue ------------------------------------------------------------------------
INSERT INTO Clue (clue_id, clue_text, clue_type) VALUES
(1, 'The elements spell what the numbers cannot.',        'Riddle'),
(2, 'Blue plus red reveals the hidden valve.',            'Visual'),
(3, 'Count the legs, then divide by the moons.',          'Riddle'),
(4, 'X marks more than the spot.',                        'Visual'),
(5, 'The captain trusts only prime numbers.',             'Riddle'),
(6, 'Listen for the third chime.',                        'Audio'),
(7, 'The file numbers ascend, the dates do not.',         'Riddle'),
(8, 'Gold is heavier than guilt.',                        'Riddle'),
(9, 'Mirror the glyphs to read them true.',               'Visual'),
(10,'The doll with two shadows knows the code.',          'Riddle');

-- Puzzle_Clue (M:N bridge) ------------------------------------------------------
INSERT INTO Puzzle_Clue (puzzle_id, clue_id, reveal_order, hint_penalty_seconds) VALUES
( 1, 1, 1, 60), ( 1, 2, 2, 90),
( 2, 2, 1, 60), ( 2, 6, 2, 120),
( 3, 3, 1, 60),
( 4, 3, 1, 45), ( 4, 4, 2, 90),
( 5, 4, 1, 60), ( 5, 5, 2, 90),
( 6, 7, 1, 60), ( 6, 6, 2, 120),
( 7, 7, 1, 60),
( 8, 8, 1, 60), ( 8, 5, 2, 90),
( 9, 8, 1, 45),
(10, 3, 1, 60), (10, 6, 2, 120),
(11, 9, 1, 60), (11, 1, 2, 90),
(12, 9, 1, 60), (12, 7, 2, 90),
(13, 4, 1, 60), (13, 2, 2, 90),
(14, 10, 1, 60), (14, 9, 2, 90);

-- Team -------------------------------------------------------------------------
INSERT INTO Team (team_id, team_name, contact_email, created_date) VALUES
(1, 'Brainiacs',       'brainiacs@mail.com',   '2024-02-10'),
(2, 'Escape Artists',  'esc.artists@mail.com', '2024-05-22'),
(3, 'The Riddlers',    'riddlers@mail.com',    '2024-09-03'),
(4, 'Ctrl Alt Defeat', 'cad@mail.com',         '2025-01-15'),
(5, 'Panic Room',      'panicroom@mail.com',   '2025-06-30'),
(6, 'Sherlock Squad',  'sherlocks@mail.com',   '2025-11-11'),
(7, 'The Lockpickers', 'lockpickers@mail.com', '2026-02-14'),
(8, 'Mensa Rejects',   'mensa.rej@mail.com',   '2026-04-01');

-- Player (weak entity: PK = team_id + player_number) -----------------------------
INSERT INTO Player (team_id, player_number, first_name, last_name, age) VALUES
(1, 1, 'Amy',     'Cloete',   24), (1, 2, 'Ben',    'October', 26), (1, 3, 'Cara', 'Adams', 23),
(2, 1, 'Dan',     'Petersen', 31), (2, 2, 'Erin',   'Solomons', 29), (2, 3, 'Faisal', 'Ismail', 33), (2, 4, 'Gail', 'Fortuin', 27),
(3, 1, 'Henry',   'Jacobs',   22), (3, 2, 'Ingrid', 'Kriel',    25),
(4, 1, 'Jason',   'November', 28), (4, 2, 'Kefilwe','Maseko',   30), (4, 3, 'Liam', 'Daniels', 26), (4, 4, 'Mia', 'Hendricks', 24),
(5, 1, 'Neo',     'Molefe',   35), (5, 2, 'Olivia', 'Brand',    32),
(6, 1, 'Peter',   'Harris',   40), (6, 2, 'Queeneth','Zulu',    38), (6, 3, 'Raj', 'Naidoo', 41),
(7, 1, 'Sara',    'Davids',   21), (7, 2, 'Tebogo', 'Mahlangu', 22),
(8, 1, 'Umar',    'Abbas',    19), (8, 2, 'Vicky',  'Swart',    20);

-- Booking ------------------------------------------------------------------------
INSERT INTO Booking (booking_id, team_id, room_id, gm_id, booking_date, start_time, num_players, total_price, booking_status, did_escape, escape_time_minutes) VALUES
( 1, 1, 1, 1, '2026-08-01', '10:00', 3,  950.00, 'Completed', TRUE,  47),
( 2, 2, 1, 2, '2026-08-02', '14:00', 4,  950.00, 'Completed', FALSE, NULL),
( 3, 3, 2, 1, '2026-08-05', '18:00', 2,  750.00, 'Completed', TRUE,  39),
( 4, 4, 4, 3, '2026-08-09', '11:00', 4,  890.00, 'Completed', TRUE,  52),
( 5, 5, 4, 4, '2026-08-10', '16:00', 2,  890.00, 'Completed', FALSE, NULL),
( 6, 6, 5, 3, '2026-08-15', '12:00', 3,  990.00, 'Completed', TRUE,  55),
( 7, 1, 5, 4, '2026-08-16', '15:00', 3,  990.00, 'Completed', TRUE,  41),
( 8, 2, 6, 3, '2026-08-22', '13:00', 4,  820.00, 'Completed', TRUE,  48),
( 9, 7, 7, 5, '2026-08-29', '17:00', 2,  780.00, 'Completed', TRUE,  44),
(10, 8, 8, 6, '2026-09-02', '19:00', 2, 1050.00, 'Completed', FALSE, NULL),
(11, 4, 7, 5, '2026-09-06', '10:00', 4,  780.00, 'Completed', TRUE,  50),
(12, 6, 1, 2, '2026-09-12', '12:00', 3,  950.00, 'Completed', TRUE,  58),
(13, 3, 4, 4, '2026-09-13', '14:00', 2,  890.00, 'Cancelled', NULL, NULL),
(14, 5, 8, 6, '2026-09-20', '20:00', 2, 1050.00, 'Completed', TRUE,  56),
(15, 7, 2, 1, '2026-10-17', '18:00', 2,  750.00, 'Scheduled', NULL, NULL),
(16, 8, 5, 3, '2026-10-24', '15:00', 2,  990.00, 'Scheduled', NULL, NULL),
(17, 1, 6, 4, '2026-10-31', '13:00', 3,  820.00, 'Scheduled', NULL, NULL);

-- Customer -----------------------------------------------------------------------
INSERT INTO Customer (customer_id, first_name, last_name, email, join_date) VALUES
( 1, 'Amy',     'Cloete',    'amy.c@mail.com',    '2024-02-10'),
( 2, 'Dan',     'Petersen',  'dan.p@mail.com',    '2024-05-22'),
( 3, 'Henry',   'Jacobs',    'henry.j@mail.com',  '2024-09-03'),
( 4, 'Jason',   'November',  'jason.n@mail.com',  '2025-01-15'),
( 5, 'Neo',     'Molefe',    'neo.m@mail.com',    '2025-06-30'),
( 6, 'Peter',   'Harris',    'peter.h@mail.com',  '2025-11-11'),
( 7, 'Sara',    'Davids',    'sara.d@mail.com',   '2026-02-14'),
( 8, 'Umar',    'Abbas',     'umar.a@mail.com',   '2026-04-01'),
( 9, 'Wendy',   'October',   'wendy.o@mail.com',  '2026-05-19'),
(10, 'Xolani',  'Gumede',    'xolani.g@mail.com', '2026-07-07');

-- Review -------------------------------------------------------------------------
INSERT INTO Review (review_id, customer_id, room_id, rating, review_text, review_date) VALUES
( 1, 1, 1, 5, 'Brilliant puzzles, the cipher had us sweating!', '2026-08-02'),
( 2, 2, 1, 4, 'Tough but fair. Great game master.',            '2026-08-03'),
( 3, 3, 2, 4, 'Fun pirate theme, a bit easy for veterans.',    '2026-08-06'),
( 4, 4, 4, 5, 'The vault puzzle is genius.',                   '2026-08-10'),
( 5, 5, 4, 3, 'Good room but one prop was broken.',            '2026-08-11'),
( 6, 6, 5, 5, 'Best sci-fi room in Joburg!',                   '2026-08-16'),
( 7, 1, 5, 4, 'Immersive, oxygen puzzle stressed us out.',     '2026-08-17'),
( 8, 2, 6, 4, 'Loved the hieroglyph wall.',                    '2026-08-23'),
( 9, 7, 7, 4, 'Knots puzzle was a workout. Fun!',              '2026-08-30'),
(10, 8, 8, 2, 'Too dark, clues were hard to read.',            '2026-09-03'),
(11, 4, 7, 5, 'Perfect team night out.',                       '2026-09-07'),
(12, 6, 1, 5, 'Second visit, still amazing.',                  '2026-09-13'),
(13, 5, 8, 4, 'Creepy in the best way.',                       '2026-09-21'),
(14, 9, 2, 3, 'Decent, but the chest lock jammed.',            '2026-09-25');

-- Maintenance_Log (weak entity: PK = room_id + log_seq) ----------------------------
INSERT INTO Maintenance_Log (room_id, log_seq, log_date, description, cost, resolved) VALUES
(3, 1, '2026-07-28', 'Electroshock panel sparking - unsafe, disabled puzzle 7.', 2200.00, TRUE),
(3, 2, '2026-08-15', 'Door magnet lock sticking between sessions.',               450.00, FALSE),
(3, 3, '2026-09-01', 'Fog machine refill and nozzle replacement.',                800.00, FALSE),
(4, 1, '2026-08-12', 'Vault door hinge lubrication.',                             150.00, TRUE),
(5, 1, '2026-08-18', 'LED starfield panel flickering in sector 3.',               600.00, TRUE),
(2, 1, '2026-09-24', 'Chest lock jamming after repeated use.',                    320.00, FALSE),
(8, 1, '2026-09-05', 'Low-light bulb replacement in hallway.',                    180.00, TRUE),
(8, 2, '2026-09-22', 'Audio speaker crackle during intro sequence.',              410.00, TRUE),
(1, 1, '2026-09-30', 'Periodic table wall decal peeling.',                        120.00, TRUE);
