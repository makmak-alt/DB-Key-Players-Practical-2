-- ============================================================================
-- CSC312 Practical Assignment 2
-- Escape Room Management System - Database Schema (3NF)
-- Team: Key Players   Members: 4427029, [ADD TEAMMATES]
-- File: 01_schema.sql
-- Target: MySQL 8.0 (server 172.21.12.21)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS CSC312_DB;
USE CSC312_DB;

-- Drop in dependency order so the script is re-runnable
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Review;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Maintenance_Log;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Player;
DROP TABLE IF EXISTS Team;
DROP TABLE IF EXISTS Puzzle_Clue;
DROP TABLE IF EXISTS Clue;
DROP TABLE IF EXISTS Puzzle;
DROP TABLE IF EXISTS Game_Master;
DROP TABLE IF EXISTS Room;
DROP TABLE IF EXISTS Venue_Phone;
DROP TABLE IF EXISTS Venue;
DROP TABLE IF EXISTS Venue_Manager;
SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Venue_Manager
-- A venue manager manages exactly one venue (1:1 enforced from Venue side).
-- ----------------------------------------------------------------------------
CREATE TABLE Venue_Manager (
    manager_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(40)  NOT NULL,
    last_name     VARCHAR(40)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL,
    hire_date     DATE         NOT NULL,
    salary        DECIMAL(10,2) NOT NULL CHECK (salary > 0)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Venue
-- 1:1 with Venue_Manager -> manager_id is UNIQUE (each venue has ONE manager,
-- and a manager manages only ONE venue).
-- ----------------------------------------------------------------------------
CREATE TABLE Venue (
    venue_id    INT AUTO_INCREMENT PRIMARY KEY,
    venue_name  VARCHAR(60)  NOT NULL,
    street      VARCHAR(80)  NOT NULL,
    city        VARCHAR(40)  NOT NULL,
    manager_id  INT          NOT NULL UNIQUE,
    open_date   DATE         NOT NULL,
    CONSTRAINT fk_venue_manager FOREIGN KEY (manager_id)
        REFERENCES Venue_Manager (manager_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- MULTIVALUED ATTRIBUTE resolved: a venue can have several contact numbers.
-- Composite PK (venue_id, phone).
-- ----------------------------------------------------------------------------
CREATE TABLE Venue_Phone (
    venue_id    INT         NOT NULL,
    phone       VARCHAR(20) NOT NULL,
    PRIMARY KEY (venue_id, phone),
    CONSTRAINT fk_venuephone_venue FOREIGN KEY (venue_id)
        REFERENCES Venue (venue_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Room (1:M Venue -> Room)
-- ----------------------------------------------------------------------------
CREATE TABLE Room (
    room_id           INT AUTO_INCREMENT PRIMARY KEY,
    venue_id          INT          NOT NULL,
    room_name         VARCHAR(60)  NOT NULL,
    theme             VARCHAR(40)  NOT NULL,
    difficulty_level  TINYINT      NOT NULL CHECK (difficulty_level BETWEEN 1 AND 5),
    min_players       TINYINT      NOT NULL CHECK (min_players >= 1),
    max_players       TINYINT      NOT NULL,
    price_per_session DECIMAL(8,2) NOT NULL CHECK (price_per_session >= 0),
    room_status       ENUM('Available','Under Maintenance','Closed') NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_room_venue FOREIGN KEY (venue_id)
        REFERENCES Venue (venue_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_room_capacity CHECK (max_players >= min_players)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Game_Master (1:M Venue -> Game_Master)
-- ----------------------------------------------------------------------------
CREATE TABLE Game_Master (
    gm_id        INT AUTO_INCREMENT PRIMARY KEY,
    venue_id     INT          NOT NULL,
    first_name   VARCHAR(40)  NOT NULL,
    last_name    VARCHAR(40)  NOT NULL,
    email        VARCHAR(100) NOT NULL UNIQUE,
    hire_date    DATE         NOT NULL,
    hourly_rate  DECIMAL(6,2) NOT NULL CHECK (hourly_rate > 0),
    CONSTRAINT fk_gm_venue FOREIGN KEY (venue_id)
        REFERENCES Venue (venue_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Puzzle (1:M Room -> Puzzle)
-- ----------------------------------------------------------------------------
CREATE TABLE Puzzle (
    puzzle_id          INT AUTO_INCREMENT PRIMARY KEY,
    room_id            INT         NOT NULL,
    puzzle_name        VARCHAR(60) NOT NULL,
    puzzle_type        VARCHAR(30) NOT NULL,   -- e.g. Logic, Physical, Cipher
    time_limit_minutes SMALLINT    NOT NULL CHECK (time_limit_minutes > 0),
    is_active          BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_puzzle_room FOREIGN KEY (room_id)
        REFERENCES Room (room_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Clue
-- ----------------------------------------------------------------------------
CREATE TABLE Clue (
    clue_id   INT AUTO_INCREMENT PRIMARY KEY,
    clue_text VARCHAR(200) NOT NULL,
    clue_type VARCHAR(30)  NOT NULL          -- e.g. Riddle, Visual, Audio
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- BRIDGE / COMPOSITE ENTITY: Puzzle_Clue  (resolves M:N Puzzle <-> Clue)
-- A puzzle can require many clues; a clue can be reused in many puzzles.
-- ----------------------------------------------------------------------------
CREATE TABLE Puzzle_Clue (
    puzzle_id            INT      NOT NULL,
    clue_id              INT      NOT NULL,
    reveal_order         TINYINT  NOT NULL,  -- order in which the clue is offered
    hint_penalty_seconds SMALLINT NOT NULL DEFAULT 0,
    PRIMARY KEY (puzzle_id, clue_id),
    CONSTRAINT fk_pc_puzzle FOREIGN KEY (puzzle_id)
        REFERENCES Puzzle (puzzle_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pc_clue FOREIGN KEY (clue_id)
        REFERENCES Clue (clue_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Team
-- ----------------------------------------------------------------------------
CREATE TABLE Team (
    team_id       INT AUTO_INCREMENT PRIMARY KEY,
    team_name     VARCHAR(60) NOT NULL UNIQUE,
    contact_email VARCHAR(100) NOT NULL,
    created_date  DATE NOT NULL
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- WEAK ENTITY: Player
-- A player only exists within a team and is identified by the team plus a
-- partial key (player_number). Deleting the team removes its players.
-- ----------------------------------------------------------------------------
CREATE TABLE Player (
    team_id       INT         NOT NULL,
    player_number TINYINT     NOT NULL,
    first_name    VARCHAR(40) NOT NULL,
    last_name     VARCHAR(40) NOT NULL,
    age           TINYINT     CHECK (age >= 10),
    PRIMARY KEY (team_id, player_number),
    CONSTRAINT fk_player_team FOREIGN KEY (team_id)
        REFERENCES Team (team_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Booking
-- 1:M Team -> Booking, 1:M Game_Master -> Booking, 1:M Room -> Booking
-- ----------------------------------------------------------------------------
CREATE TABLE Booking (
    booking_id          INT AUTO_INCREMENT PRIMARY KEY,
    team_id             INT      NOT NULL,
    room_id             INT      NOT NULL,
    gm_id               INT      NOT NULL,
    booking_date        DATE     NOT NULL,
    start_time          TIME     NOT NULL,
    num_players         TINYINT  NOT NULL CHECK (num_players > 0),
    total_price         DECIMAL(8,2) NOT NULL CHECK (total_price >= 0),
    booking_status      ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    did_escape          BOOLEAN  NULL,        -- NULL until the session is played
    escape_time_minutes SMALLINT NULL,        -- derived insight: performance
    CONSTRAINT fk_booking_team FOREIGN KEY (team_id)
        REFERENCES Team (team_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_booking_room FOREIGN KEY (room_id)
        REFERENCES Room (room_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_booking_gm FOREIGN KEY (gm_id)
        REFERENCES Game_Master (gm_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- WEAK ENTITY: Maintenance_Log (1:M Room -> Maintenance_Log)
-- A log entry is meaningless without its room: composite PK (room_id, log_seq).
-- ----------------------------------------------------------------------------
CREATE TABLE Maintenance_Log (
    room_id     INT           NOT NULL,
    log_seq     SMALLINT      NOT NULL,
    log_date    DATE          NOT NULL,
    description VARCHAR(200)  NOT NULL,
    cost        DECIMAL(8,2)  NOT NULL DEFAULT 0 CHECK (cost >= 0),
    resolved    BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (room_id, log_seq),
    CONSTRAINT fk_mlog_room FOREIGN KEY (room_id)
        REFERENCES Room (room_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Customer
-- ----------------------------------------------------------------------------
CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name  VARCHAR(40)  NOT NULL,
    last_name   VARCHAR(40)  NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    join_date   DATE         NOT NULL
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- STRONG ENTITY: Review (1:M Customer -> Review, 1:M Room -> Review)
-- ----------------------------------------------------------------------------
CREATE TABLE Review (
    review_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT      NOT NULL,
    room_id      INT      NOT NULL,
    rating       TINYINT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text  VARCHAR(300),
    review_date  DATE     NOT NULL,
    CONSTRAINT fk_review_customer FOREIGN KEY (customer_id)
        REFERENCES Customer (customer_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_review_room FOREIGN KEY (room_id)
        REFERENCES Room (room_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT uq_review UNIQUE (customer_id, room_id)  -- one review per customer per room
) ENGINE = InnoDB;
