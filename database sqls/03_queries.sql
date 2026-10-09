-- ============================================================================
-- CSC312 Practical Assignment 2
-- Escape Room Management System - Analysis Queries
-- Team: Key Players   Members: 4427029, [ADD TEAMMATES]
-- File: 03_queries.sql  (run after 01_schema.sql and 02_data.sql)
-- 11 queries: 2 simple (Q1-Q2), 4 medium (Q3-Q6), 5 complex (Q7-Q11)
-- ============================================================================

USE CSC312_DB;

-- ----------------------------------------------------------------------------
-- Q1 (SIMPLE - single table, WHERE + ORDER BY)
-- Context: A customer walks in and asks "what horror rooms do you have and
-- what do they cost?" - the front desk needs a quick, filterable answer.
-- ----------------------------------------------------------------------------
SELECT room_name,
       theme,
       difficulty_level,
       price_per_session
FROM   Room
WHERE  theme = 'Horror'
ORDER  BY price_per_session;

-- ----------------------------------------------------------------------------
-- Q2 (SIMPLE - single table, WHERE on date + ORDER BY)
-- Context: Marketing wants the list of customers who joined in 2026, so the
-- new-customer welcome campaign only mails recent sign-ups.
-- ----------------------------------------------------------------------------
SELECT first_name,
       last_name,
       email,
       join_date
FROM   Customer
WHERE  join_date >= '2026-01-01'
ORDER  BY join_date;

-- ----------------------------------------------------------------------------
-- Q3 (MEDIUM - joins + aggregation with GROUP BY)
-- Context: Management wants to know which venues generate the most revenue
-- from completed sessions, to guide marketing spend and expansion decisions.
-- ----------------------------------------------------------------------------
SELECT v.venue_name,
       v.city,
       COUNT(b.booking_id)      AS completed_sessions,
       SUM(b.total_price)       AS total_revenue,
       AVG(b.total_price)       AS avg_session_price
FROM   Venue v
       INNER JOIN Room r    ON r.venue_id = v.venue_id
       INNER JOIN Booking b ON b.room_id  = r.room_id
WHERE  b.booking_status = 'Completed'
GROUP  BY v.venue_id, v.venue_name, v.city
ORDER  BY total_revenue DESC;

-- ----------------------------------------------------------------------------
-- Q4 (MEDIUM - LEFT JOIN + string functions)
-- Context: The marketing team wants a re-engagement list: registered customers
-- who have never left a review, so they can be emailed a feedback voucher.
-- ----------------------------------------------------------------------------
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       c.email,
       c.join_date
FROM   Customer c
       LEFT JOIN Review rv ON rv.customer_id = c.customer_id
WHERE  rv.review_id IS NULL
ORDER  BY c.join_date;

-- ----------------------------------------------------------------------------
-- Q5 (MEDIUM - multi-table join + date functions)
-- Context: Front-of-house staff need the upcoming schedule showing which team
-- plays which room, at which venue, and which game master is running it.
-- ----------------------------------------------------------------------------
SELECT DATE_FORMAT(b.booking_date, '%W %d %M %Y') AS session_day,
       TIME_FORMAT(b.start_time, '%H:%i')         AS start_at,
       t.team_name,
       r.room_name,
       v.venue_name,
       CONCAT(g.first_name, ' ', g.last_name)     AS game_master,
       b.num_players
FROM   Booking b
       INNER JOIN Team        t ON t.team_id = b.team_id
       INNER JOIN Room        r ON r.room_id = b.room_id
       INNER JOIN Venue       v ON v.venue_id = r.venue_id
       INNER JOIN Game_Master g ON g.gm_id    = b.gm_id
WHERE  b.booking_status = 'Scheduled'
ORDER  BY b.booking_date, b.start_time;

-- ----------------------------------------------------------------------------
-- Q6 (MEDIUM - subquery in HAVING)
-- Context: Quality control - find rooms whose average customer rating is above
-- the company-wide average, so their designs can be used as templates.
-- ----------------------------------------------------------------------------
SELECT r.room_name,
       v.venue_name,
       AVG(rv.rating) AS avg_rating,
       COUNT(rv.review_id) AS num_reviews
FROM   Room r
       INNER JOIN Venue v  ON v.venue_id = r.venue_id
       INNER JOIN Review rv ON rv.room_id = r.room_id
GROUP  BY r.room_id, r.room_name, v.venue_name
HAVING AVG(rv.rating) > (SELECT AVG(rating) FROM Review)
ORDER  BY avg_rating DESC;

-- ----------------------------------------------------------------------------
-- Q7 (COMPLEX - aggregation + HAVING + nested subquery)
-- Context: Loyalty programme - identify repeat teams (more than one completed
-- booking) whose total spend is above the average spend per team. These teams
-- qualify for the loyalty discount.
-- ----------------------------------------------------------------------------
SELECT t.team_name,
       COUNT(b.booking_id)  AS sessions_played,
       SUM(b.total_price)   AS total_spent,
       AVG(b.total_price)   AS avg_spent_per_session
FROM   Team t
       INNER JOIN Booking b ON b.team_id = t.team_id
WHERE  b.booking_status = 'Completed'
GROUP  BY t.team_id, t.team_name
HAVING COUNT(b.booking_id) > 1
   AND SUM(b.total_price) > (SELECT AVG(team_total)
                             FROM (SELECT SUM(total_price) AS team_total
                                   FROM   Booking
                                   WHERE  booking_status = 'Completed'
                                   GROUP  BY team_id) AS spend)
ORDER  BY total_spent DESC;

-- ----------------------------------------------------------------------------
-- Q8 (COMPLEX - M:N bridge entity, GROUP BY + HAVING)
-- Context: Puzzle designers want to know which clues are reused across
-- multiple puzzles (to avoid over-exposing regular players to the same clue)
-- and how many clues each puzzle depends on.
-- ----------------------------------------------------------------------------
SELECT c.clue_id,
       c.clue_text,
       c.clue_type,
       COUNT(pc.puzzle_id) AS puzzles_using_clue
FROM   Clue c
       INNER JOIN Puzzle_Clue pc ON pc.clue_id = c.clue_id
GROUP  BY c.clue_id, c.clue_text, c.clue_type
HAVING COUNT(pc.puzzle_id) > 1
ORDER  BY puzzles_using_clue DESC;

-- ----------------------------------------------------------------------------
-- Q9 (COMPLEX - 3-table join + HAVING vs nested subquery)
-- Context: Executive view - which venues outperform the company-wide average
-- room rating, and by how much? Feeds the venue scorecard.
-- ----------------------------------------------------------------------------
SELECT v.venue_name,
       v.city,
       COUNT(rv.review_id) AS total_reviews,
       ROUND(AVG(rv.rating), 2) AS venue_avg_rating,
       ROUND((SELECT AVG(rating) FROM Review), 2) AS company_avg_rating
FROM   Venue v
       INNER JOIN Room r   ON r.venue_id = v.venue_id
       INNER JOIN Review rv ON rv.room_id = r.room_id
GROUP  BY v.venue_id, v.venue_name, v.city
HAVING AVG(rv.rating) > (SELECT AVG(rating) FROM Review)
ORDER  BY venue_avg_rating DESC;

-- ----------------------------------------------------------------------------
-- Q10 (COMPLEX - multiple AND/OR conditions + HAVING after aggregation)
-- Context: Risk report for operations - rooms that are a maintenance risk:
-- either they already have unresolved maintenance issues, or their total
-- maintenance spend has exceeded R500. These rooms may need to be taken
-- offline before peak season.
-- ----------------------------------------------------------------------------
SELECT r.room_name,
       v.venue_name,
       r.room_status,
       COUNT(m.log_seq)                          AS total_logs,
       SUM(CASE WHEN m.resolved = FALSE THEN 1 ELSE 0 END) AS unresolved_issues,
       SUM(m.cost)                               AS total_maintenance_cost
FROM   Room r
       INNER JOIN Venue v          ON v.venue_id = v.venue_id
       INNER JOIN Maintenance_Log m ON m.room_id = r.room_id
GROUP  BY r.room_id, r.room_name, v.venue_name, r.room_status
HAVING SUM(CASE WHEN m.resolved = FALSE THEN 1 ELSE 0 END) > 0
   OR  SUM(m.cost) > 500
ORDER  BY unresolved_issues DESC, total_maintenance_cost DESC;

-- ----------------------------------------------------------------------------
-- Q11 (COMPLEX - derived metric: escape rate, aggregation + CASE + HAVING)
-- Context: Game design - the escape rate per difficulty level tells us whether
-- our difficulty labels are calibrated. If level-5 rooms have a higher escape
-- rate than level-2 rooms, the labelling is misleading customers.
-- ----------------------------------------------------------------------------
SELECT r.difficulty_level,
       COUNT(b.booking_id)                                              AS sessions_played,
       SUM(CASE WHEN b.did_escape = TRUE THEN 1 ELSE 0 END)             AS escapes,
       ROUND(100 * SUM(CASE WHEN b.did_escape = TRUE THEN 1 ELSE 0 END)
                   / COUNT(b.booking_id), 1)                            AS escape_rate_pct,
       ROUND(AVG(b.escape_time_minutes), 1)                             AS avg_escape_time_min
FROM   Room r
       INNER JOIN Booking b ON b.room_id = r.room_id
WHERE  b.booking_status = 'Completed'
GROUP  BY r.difficulty_level
HAVING COUNT(b.booking_id) >= 1
ORDER  BY r.difficulty_level;
