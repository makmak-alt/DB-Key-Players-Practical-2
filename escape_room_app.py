#!/usr/bin/env python3
# ============================================================================
# CSC312 Practical Assignment 2
# Team:   Key Players
# Members: 4427029, [ADD TEAMMATES' STUDENT NUMBERS]
# File:   escape_room_app.py
#
# Escape Room Management System - database client.
# Connects to the team's MySQL 8 server over SSL and lets the user run all
# 11 project queries from report section 6.0 (2 simple, 4 medium, 5 complex),
# or create a new booking inside a transaction (with rollback on failure).
#
# Usage:  python3 escape_room_app.py
# Deps:   pip install mysql-connector-python
# ============================================================================

import getpass
import sys
import mysql.connector
from mysql.connector import Error

DB_CONFIG = {
    "host": "172.21.12.21",
    "port": 27029,               # 2 + last four digits of student number
    "user": "4427029",
    "database": "CSC312_DB",
    "ssl_verify_cert": False,    # server uses a self-signed certificate
    "autocommit": True,          # SELECTs stay clean; booking uses an explicit transaction
}

QUERIES = {
    "1": ("Horror rooms and their prices (SIMPLE)",
          """SELECT room_name, theme, difficulty_level, price_per_session
             FROM Room
             WHERE theme = 'Horror'
             ORDER BY price_per_session"""),
    "2": ("Customers who joined in 2026 (SIMPLE)",
          """SELECT first_name, last_name, email, join_date
             FROM Customer
             WHERE join_date >= '2026-01-01'
             ORDER BY join_date"""),
    "3": ("Revenue per venue (completed sessions) (MEDIUM)",
          """SELECT v.venue_name, v.city,
                    COUNT(b.booking_id) AS completed_sessions,
                    SUM(b.total_price)  AS total_revenue,
                    AVG(b.total_price)  AS avg_session_price
             FROM Venue v
             INNER JOIN Room r    ON r.venue_id = v.venue_id
             INNER JOIN Booking b ON b.room_id  = r.room_id
             WHERE b.booking_status = 'Completed'
             GROUP BY v.venue_id, v.venue_name, v.city
             ORDER BY total_revenue DESC"""),
    "4": ("Customers who have never reviewed (MEDIUM)",
          """SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
                    c.email, c.join_date
             FROM Customer c
             LEFT JOIN Review rv ON rv.customer_id = c.customer_id
             WHERE rv.review_id IS NULL
             ORDER BY c.join_date"""),
    "5": ("Upcoming scheduled sessions (MEDIUM)",
          """SELECT DATE_FORMAT(b.booking_date, '%W %d %M %Y') AS session_day,
                    TIME_FORMAT(b.start_time, '%H:%i')         AS start_at,
                    t.team_name, r.room_name, v.venue_name,
                    CONCAT(g.first_name, ' ', g.last_name)     AS game_master,
                    b.num_players
             FROM Booking b
             INNER JOIN Team        t ON t.team_id = b.team_id
             INNER JOIN Room        r ON r.room_id = b.room_id
             INNER JOIN Venue       v ON v.venue_id = r.venue_id
             INNER JOIN Game_Master g ON g.gm_id    = b.gm_id
             WHERE b.booking_status = 'Scheduled'
             ORDER BY b.booking_date, b.start_time"""),
    "6": ("Rooms rated above the company average (MEDIUM)",
          """SELECT r.room_name, v.venue_name,
                    AVG(rv.rating)      AS avg_rating,
                    COUNT(rv.review_id) AS num_reviews
             FROM Room r
             INNER JOIN Venue v   ON v.venue_id = r.venue_id
             INNER JOIN Review rv ON rv.room_id = r.room_id
             GROUP BY r.room_id, r.room_name, v.venue_name
             HAVING AVG(rv.rating) > (SELECT AVG(rating) FROM Review)
             ORDER BY avg_rating DESC"""),
    "7": ("Loyalty teams: repeat + above-average spend (COMPLEX)",
          """SELECT t.team_name,
                    COUNT(b.booking_id) AS sessions_played,
                    SUM(b.total_price)  AS total_spent,
                    AVG(b.total_price)  AS avg_spent_per_session
             FROM Team t
             INNER JOIN Booking b ON b.team_id = t.team_id
             WHERE b.booking_status = 'Completed'
             GROUP BY t.team_id, t.team_name
             HAVING COUNT(b.booking_id) > 1
                AND SUM(b.total_price) > (SELECT AVG(team_total)
                                          FROM (SELECT SUM(total_price) AS team_total
                                                FROM Booking
                                                WHERE booking_status = 'Completed'
                                                GROUP BY team_id) AS spend)
             ORDER BY total_spent DESC"""),
    "8": ("Clues reused across multiple puzzles (COMPLEX)",
          """SELECT c.clue_id, c.clue_text, c.clue_type,
                    COUNT(pc.puzzle_id) AS puzzles_using_clue
             FROM Clue c
             INNER JOIN Puzzle_Clue pc ON pc.clue_id = c.clue_id
             GROUP BY c.clue_id, c.clue_text, c.clue_type
             HAVING COUNT(pc.puzzle_id) > 1
             ORDER BY puzzles_using_clue DESC"""),
    "9": ("Venues outperforming the company-wide rating (COMPLEX)",
          """SELECT v.venue_name, v.city,
                    COUNT(rv.review_id)        AS total_reviews,
                    ROUND(AVG(rv.rating), 2)   AS venue_avg_rating,
                    ROUND((SELECT AVG(rating) FROM Review), 2) AS company_avg_rating
             FROM Venue v
             INNER JOIN Room r    ON v.venue_id = r.venue_id
             INNER JOIN Review rv ON rv.room_id = r.room_id
             GROUP BY v.venue_id, v.venue_name, v.city
             HAVING AVG(rv.rating) > (SELECT AVG(rating) FROM Review)
             ORDER BY venue_avg_rating DESC"""),
    "10": ("Maintenance risk report (COMPLEX)",
           """SELECT r.room_name, v.venue_name, r.room_status,
                    COUNT(m.log_seq) AS total_logs,
                    SUM(CASE WHEN m.resolved = FALSE THEN 1 ELSE 0 END) AS unresolved_issues,
                    SUM(m.cost) AS total_maintenance_cost
             FROM Room r
             INNER JOIN Venue v           ON v.venue_id = r.venue_id
             INNER JOIN Maintenance_Log m ON m.room_id = r.room_id
             GROUP BY r.room_id, r.room_name, v.venue_name, r.room_status
             HAVING SUM(CASE WHEN m.resolved = FALSE THEN 1 ELSE 0 END) > 0
                 OR SUM(m.cost) > 500
             ORDER BY unresolved_issues DESC, total_maintenance_cost DESC"""),
    "11": ("Escape rate per difficulty level (COMPLEX)",
           """SELECT r.difficulty_level,
                    COUNT(b.booking_id) AS sessions_played,
                    SUM(CASE WHEN b.did_escape = TRUE THEN 1 ELSE 0 END) AS escapes,
                    ROUND(100 * SUM(CASE WHEN b.did_escape = TRUE THEN 1 ELSE 0 END)
                                / COUNT(b.booking_id), 1) AS escape_rate_pct,
                    ROUND(AVG(b.escape_time_minutes), 1)  AS avg_escape_time_min
             FROM Room r
             INNER JOIN Booking b ON b.room_id = r.room_id
             WHERE b.booking_status = 'Completed'
             GROUP BY r.difficulty_level
             ORDER BY r.difficulty_level"""),
}


def connect():
    """Prompt for the password and open an SSL connection to the server."""
    password = getpass.getpass("MySQL password for user %s: " % DB_CONFIG["user"])
    try:
        conn = mysql.connector.connect(password=password, **DB_CONFIG)
    except Error as err:
        print("Connection failed:", err)
        sys.exit(1)
    print("Connected to", conn.get_server_info(), "as", conn.user, "\n")
    return conn


def print_rows(cursor):
    """Print a query result set as a simple aligned text table."""
    columns = [col[0] for col in cursor.description]
    rows = cursor.fetchall()
    if not rows:
        print("(no rows returned)\n")
        return
    widths = [len(c) for c in columns]
    for row in rows:
        for i, value in enumerate(row):
            widths[i] = max(widths[i], len(str(value)))
    header = " | ".join(c.ljust(widths[i]) for i, c in enumerate(columns))
    print(header)
    print("-" * len(header))
    for row in rows:
        print(" | ".join(str(v).ljust(widths[i]) for i, v in enumerate(row)))
    print("(%d row%s)\n" % (len(rows), "" if len(rows) == 1 else "s"))


def run_query(conn, key):
    title, sql = QUERIES[key]
    print("Q%s - %s" % (key, title))
    print("=" * 70)
    cursor = conn.cursor()
    cursor.execute(sql)
    print_rows(cursor)
    cursor.close()


def create_booking(conn):
    """Insert a booking inside a transaction; roll back if anything fails."""
    print("\nCreate a new booking (transaction demo)")
    team_id = input("  Team ID: ").strip()
    room_id = input("  Room ID: ").strip()
    gm_id = input("  Game Master ID: ").strip()
    date = input("  Date (YYYY-MM-DD): ").strip()
    time = input("  Start time (HH:MM): ").strip()
    players = int(input("  Number of players: ").strip())

    cursor = conn.cursor()
    try:
        conn.start_transaction()

        # Business rule: party size must fit the room's capacity.
        cursor.execute(
            "SELECT min_players, max_players, price_per_session "
            "FROM Room WHERE room_id = %s", (room_id,))
        room = cursor.fetchone()
        if room is None:
            raise ValueError("Room %s does not exist" % room_id)
        if not (room[0] <= players <= room[1]):
            raise ValueError(
                "Room capacity is %d-%d players; %d is not allowed"
                % (room[0], room[1], players))

        cursor.execute(
            """INSERT INTO Booking
                   (team_id, room_id, gm_id, booking_date, start_time,
                    num_players, total_price, booking_status)
               VALUES (%s, %s, %s, %s, %s, %s, %s, 'Scheduled')""",
            (team_id, room_id, gm_id, date, time, players, room[2]))
        conn.commit()
        print("  Booking created with ID %d (charged R%.2f).\n"
              % (cursor.lastrowid, room[2]))
    except (Error, ValueError) as err:
        conn.rollback()
        print("  Booking rolled back: %s\n" % err)
    finally:
        cursor.close()


def main():
    conn = connect()
    menu = ("\nPick a query to run:\n"
            + "\n".join("  %-2s. %s" % (k, v[0]) for k, v in QUERIES.items())
            + "\n  b. Create a booking (transaction demo)"
              "\n  q. Quit\n")
    while True:
        print(menu)
        choice = input("Choice: ").strip().lower()
        if choice == "q":
            break
        if choice == "b":
            create_booking(conn)
        elif choice in QUERIES:
            run_query(conn, choice)
        else:
            print("Invalid choice.")
    conn.close()
    print("Connection closed. Goodbye!")


if __name__ == "__main__":
    main()
