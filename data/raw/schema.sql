-- ============================================================================
--  NexaTel Digital Services Pvt. Ltd.
--  Customer Churn Analytics — Database Schema
--  schema.sql  ·  24 tables
--
--  Compatible with MySQL, PostgreSQL and SQLite.
--  Date columns hold text in DD-MM-YYYY format (see IMPORT NOTES at the bottom).
--  Tables are created in dependency order so the script runs top to bottom.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- REFERENCE / DIMENSION TABLES
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS states;
CREATE TABLE states (
    state_id      VARCHAR(8)   PRIMARY KEY,
    state_name    VARCHAR(80),
    state_code    VARCHAR(4),
    zone          VARCHAR(10)
);

DROP TABLE IF EXISTS regions;
CREATE TABLE regions (
    region_id     VARCHAR(6)   PRIMARY KEY,
    region_name   VARCHAR(20),
    zone_hq_city  VARCHAR(40)
);

DROP TABLE IF EXISTS cities;
CREATE TABLE cities (
    city_id       VARCHAR(8)   PRIMARY KEY,
    city_name     VARCHAR(60),
    state_id      VARCHAR(8),            -- FK -> states.state_id
    state_name    VARCHAR(80),
    zone          VARCHAR(10),
    region_id     VARCHAR(6),            -- FK -> regions.region_id
    tier          VARCHAR(10),           -- Metro / Tier-2 / Tier-3
    pin_prefix    VARCHAR(4)
);

DROP TABLE IF EXISTS plans;
CREATE TABLE plans (
    plan_id        VARCHAR(8)  PRIMARY KEY,
    plan_name      VARCHAR(60),
    product_line   VARCHAR(40),
    billing_cycle  VARCHAR(20),          -- Monthly / Annual
    monthly_charge DECIMAL(10,2),
    data_quota_gb  INT,                   -- -1 = unlimited
    voice_minutes  INT,                   -- -1 = unlimited
    sms_count      INT,                   -- -1 = unlimited
    segment        VARCHAR(20),
    is_active      VARCHAR(4)
);

DROP TABLE IF EXISTS stores;
CREATE TABLE stores (
    store_id     VARCHAR(8)  PRIMARY KEY,
    store_name   VARCHAR(80),
    city_id      VARCHAR(8),              -- FK -> cities.city_id
    state_id     VARCHAR(8),              -- FK -> states.state_id
    region_id    VARCHAR(6),              -- FK -> regions.region_id
    store_type   VARCHAR(30),
    opened_date  VARCHAR(12)              -- DD-MM-YYYY
);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    employee_id    VARCHAR(8)  PRIMARY KEY,
    employee_name  VARCHAR(80),
    gender         VARCHAR(10),
    department     VARCHAR(40),
    role           VARCHAR(40),
    store_id       VARCHAR(8),            -- FK -> stores.store_id
    region_id      VARCHAR(6),            -- FK -> regions.region_id
    hire_date      VARCHAR(12),           -- DD-MM-YYYY
    email          VARCHAR(120)
);

-- ---------------------------------------------------------------------------
-- CORE ENTITY
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id        VARCHAR(12) PRIMARY KEY,
    first_name         VARCHAR(50),
    last_name          VARCHAR(50),
    gender             VARCHAR(10),
    date_of_birth      VARCHAR(12),       -- DD-MM-YYYY
    age                INT,
    email              VARCHAR(120),
    phone_number       VARCHAR(20),
    address            VARCHAR(200),
    city_id            VARCHAR(8),         -- FK -> cities.city_id
    city_name          VARCHAR(60),
    state_id           VARCHAR(8),         -- FK -> states.state_id
    pin_code           VARCHAR(10),
    city_tier          VARCHAR(10),
    region_id          VARCHAR(6),         -- FK -> regions.region_id
    occupation         VARCHAR(60),
    annual_income_inr  DECIMAL(14,2),
    customer_segment   VARCHAR(20),        -- Mass / Value / Premium / Enterprise
    product_line       VARCHAR(40),
    plan_id            VARCHAR(8),         -- FK -> plans.plan_id
    acquisition_channel VARCHAR(40),
    acquisition_date   VARCHAR(12),        -- DD-MM-YYYY
    tenure_months      INT,
    customer_status    VARCHAR(20),        -- Active / Churned
    churn_date         VARCHAR(12)         -- DD-MM-YYYY (blank if Active)
);

-- ---------------------------------------------------------------------------
-- SUBSCRIPTION / PLAN / CONTRACT / DEVICE
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS subscriptions;
CREATE TABLE subscriptions (
    subscription_id     VARCHAR(12) PRIMARY KEY,
    customer_id         VARCHAR(12),       -- FK -> customers.customer_id
    plan_id             VARCHAR(8),         -- FK -> plans.plan_id
    start_date          VARCHAR(12),        -- DD-MM-YYYY
    end_date            VARCHAR(12),        -- DD-MM-YYYY (blank if active)
    billing_cycle       VARCHAR(20),
    monthly_charge_inr  DECIMAL(10,2),
    subscription_status VARCHAR(20)         -- Active / Terminated
);

DROP TABLE IF EXISTS plan_history;
CREATE TABLE plan_history (
    history_id    VARCHAR(12) PRIMARY KEY,
    customer_id   VARCHAR(12),             -- FK -> customers.customer_id
    old_plan_id   VARCHAR(8),               -- FK -> plans.plan_id
    new_plan_id   VARCHAR(8),               -- FK -> plans.plan_id
    change_date   VARCHAR(12),              -- DD-MM-YYYY
    change_reason VARCHAR(60)
);

DROP TABLE IF EXISTS contracts;
CREATE TABLE contracts (
    contract_id            VARCHAR(10) PRIMARY KEY,
    customer_id            VARCHAR(12),     -- FK -> customers.customer_id
    plan_id                VARCHAR(8),       -- FK -> plans.plan_id
    contract_type          VARCHAR(40),
    contract_length_months INT,
    start_date             VARCHAR(12),      -- DD-MM-YYYY
    end_date               VARCHAR(12),      -- DD-MM-YYYY
    auto_renew             VARCHAR(4),
    renewal_status         VARCHAR(20)
);

DROP TABLE IF EXISTS devices;
CREATE TABLE devices (
    device_id        VARCHAR(12) PRIMARY KEY,
    customer_id      VARCHAR(12),           -- FK -> customers.customer_id
    brand            VARCHAR(40),
    model            VARCHAR(40),
    device_type      VARCHAR(30),
    device_price_inr DECIMAL(10,2),
    purchase_date    VARCHAR(12),           -- DD-MM-YYYY
    imei             VARCHAR(20)
);

-- ---------------------------------------------------------------------------
-- BILLING / PAYMENTS / RECHARGES
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS billing;
CREATE TABLE billing (
    invoice_id           VARCHAR(14) PRIMARY KEY,
    customer_id          VARCHAR(12),       -- FK -> customers.customer_id
    billing_date         VARCHAR(12),        -- DD-MM-YYYY
    billing_period_month VARCHAR(10),         -- MM-YYYY
    base_amount_inr      DECIMAL(12,2),
    gst_amount_inr       DECIMAL(12,2),
    total_amount_inr     DECIMAL(12,2),
    due_date             VARCHAR(12),         -- DD-MM-YYYY
    payment_status       VARCHAR(20)          -- Paid / Unpaid / Overdue
);

DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    payment_id     VARCHAR(14) PRIMARY KEY,
    invoice_id     VARCHAR(14),             -- FK -> billing.invoice_id
    customer_id    VARCHAR(12),             -- FK -> customers.customer_id
    payment_date   VARCHAR(12),             -- DD-MM-YYYY
    amount_inr     DECIMAL(12,2),
    payment_method VARCHAR(20),             -- UPI / Credit Card / ... / RTGS
    payment_status VARCHAR(20)
);

DROP TABLE IF EXISTS recharges;
CREATE TABLE recharges (
    recharge_id    VARCHAR(14) PRIMARY KEY,
    customer_id    VARCHAR(12),             -- FK -> customers.customer_id
    recharge_date  VARCHAR(12),             -- DD-MM-YYYY
    amount_inr     DECIMAL(10,2),
    plan_id        VARCHAR(8),               -- FK -> plans.plan_id
    payment_method VARCHAR(20)
);

-- ---------------------------------------------------------------------------
-- USAGE / NETWORK
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS usage_voice;
CREATE TABLE usage_voice (
    usage_id           VARCHAR(12) PRIMARY KEY,
    customer_id        VARCHAR(12),         -- FK -> customers.customer_id
    usage_month        VARCHAR(10),          -- MM-YYYY
    voice_minutes_used INT,
    outgoing_calls     INT,
    incoming_calls     INT
);

DROP TABLE IF EXISTS usage_sms;
CREATE TABLE usage_sms (
    usage_id      VARCHAR(12) PRIMARY KEY,
    customer_id   VARCHAR(12),              -- FK -> customers.customer_id
    usage_month   VARCHAR(10),               -- MM-YYYY
    sms_sent      INT,
    sms_received  INT
);

DROP TABLE IF EXISTS usage_data;
CREATE TABLE usage_data (
    usage_id      VARCHAR(12) PRIMARY KEY,
    customer_id   VARCHAR(12),              -- FK -> customers.customer_id
    usage_month   VARCHAR(10),               -- MM-YYYY
    data_gb_used  DECIMAL(10,2),
    data_sessions INT
);

DROP TABLE IF EXISTS network_quality;
CREATE TABLE network_quality (
    record_id               VARCHAR(12) PRIMARY KEY,
    customer_id             VARCHAR(12),     -- FK -> customers.customer_id
    city_id                 VARCHAR(8),       -- FK -> cities.city_id
    month                   VARCHAR(10),       -- MM-YYYY
    avg_signal_strength_dbm DECIMAL(6,1),
    dropped_call_rate_pct   DECIMAL(6,2),
    avg_download_speed_mbps DECIMAL(7,1),
    network_downtime_hours  DECIMAL(7,2)
);

-- ---------------------------------------------------------------------------
-- SUPPORT / COMPLAINTS / FEEDBACK
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS support_tickets;
CREATE TABLE support_tickets (
    ticket_id                VARCHAR(12) PRIMARY KEY,
    customer_id              VARCHAR(12),    -- FK -> customers.customer_id
    created_date             VARCHAR(12),     -- DD-MM-YYYY
    category                 VARCHAR(40),
    priority                 VARCHAR(20),     -- Low / Medium / High / Critical
    channel                  VARCHAR(20),
    status                   VARCHAR(20),     -- Resolved / Pending / Escalated / Reopened
    first_contact_resolution VARCHAR(4),      -- Yes / No
    assigned_employee_id     VARCHAR(8),       -- FK -> employees.employee_id
    resolution_hours         DECIMAL(8,1),
    resolution_date          VARCHAR(12)       -- DD-MM-YYYY (blank if unresolved)
);

DROP TABLE IF EXISTS complaints;
CREATE TABLE complaints (
    complaint_id    VARCHAR(12) PRIMARY KEY,
    customer_id     VARCHAR(12),             -- FK -> customers.customer_id
    complaint_date  VARCHAR(12),              -- DD-MM-YYYY
    complaint_type  VARCHAR(40),
    severity        VARCHAR(20),              -- Minor / Moderate / Major / Severe
    status          VARCHAR(20),              -- Resolved / Unresolved
    resolution_date VARCHAR(12)               -- DD-MM-YYYY (blank if unresolved)
);

DROP TABLE IF EXISTS customer_feedback;
CREATE TABLE customer_feedback (
    feedback_id       VARCHAR(12) PRIMARY KEY,
    customer_id       VARCHAR(12),           -- FK -> customers.customer_id
    feedback_date     VARCHAR(12),            -- DD-MM-YYYY
    csat_score        INT,                     -- 1..5
    nps_score         INT,                     -- 0..10
    channel           VARCHAR(30),
    feedback_category VARCHAR(40)
);

-- ---------------------------------------------------------------------------
-- CAMPAIGNS
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS retention_campaigns;
CREATE TABLE retention_campaigns (
    campaign_id   VARCHAR(12) PRIMARY KEY,
    customer_id   VARCHAR(12),               -- FK -> customers.customer_id
    campaign_name VARCHAR(60),
    offer_type    VARCHAR(60),
    contact_date  VARCHAR(12),                -- DD-MM-YYYY
    channel       VARCHAR(20),
    response      VARCHAR(20),                -- Accepted / Declined / No Response
    retained_flag VARCHAR(4)                  -- Yes / No
);

DROP TABLE IF EXISTS marketing_campaigns;
CREATE TABLE marketing_campaigns (
    campaign_id       VARCHAR(10) PRIMARY KEY,
    campaign_name     VARCHAR(80),
    channel           VARCHAR(30),
    target_segment    VARCHAR(30),
    start_date        VARCHAR(12),            -- DD-MM-YYYY
    end_date          VARCHAR(12),            -- DD-MM-YYYY
    budget_inr        DECIMAL(14,2),
    customers_reached INT,
    conversions       INT
);

-- ---------------------------------------------------------------------------
-- DATA QUALITY ISSUE LOG (companion reference table)
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS data_quality_issue_log;
CREATE TABLE data_quality_issue_log (
    issue_table   VARCHAR(40),
    issue_type    VARCHAR(60),
    rows_affected INT
);

-- ============================================================================
--  OPTIONAL: FOREIGN KEY CONSTRAINTS
--  Add these AFTER the data is loaded and cleaned. A small number of rows
--  contain deliberately broken or missing keys (part of the cleaning work),
--  so adding these constraints before cleaning will reject those rows.
-- ============================================================================
-- ALTER TABLE customers           ADD FOREIGN KEY (city_id)   REFERENCES cities(city_id);
-- ALTER TABLE customers           ADD FOREIGN KEY (state_id)  REFERENCES states(state_id);
-- ALTER TABLE customers           ADD FOREIGN KEY (region_id) REFERENCES regions(region_id);
-- ALTER TABLE customers           ADD FOREIGN KEY (plan_id)   REFERENCES plans(plan_id);
-- ALTER TABLE subscriptions       ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE subscriptions       ADD FOREIGN KEY (plan_id)     REFERENCES plans(plan_id);
-- ALTER TABLE plan_history        ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE contracts           ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE devices             ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE billing             ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE payments            ADD FOREIGN KEY (invoice_id)  REFERENCES billing(invoice_id);
-- ALTER TABLE payments            ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE recharges           ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE usage_voice         ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE usage_sms           ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE usage_data          ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE network_quality     ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE support_tickets     ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE support_tickets     ADD FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id);
-- ALTER TABLE complaints          ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE customer_feedback   ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE retention_campaigns ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
-- ALTER TABLE employees           ADD FOREIGN KEY (store_id)  REFERENCES stores(store_id);
-- ALTER TABLE stores              ADD FOREIGN KEY (city_id)   REFERENCES cities(city_id);
-- ALTER TABLE cities              ADD FOREIGN KEY (state_id)  REFERENCES states(state_id);

-- ============================================================================
--  IMPORT NOTES
-- ============================================================================
--  Load the tables in the same order they are created above (parents first).
--
--  MySQL  (run once per file; adjust the path):
--    LOAD DATA INFILE '/path/customers.csv'
--    INTO TABLE customers
--    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
--    LINES TERMINATED BY '\n' IGNORE 1 LINES;
--
--  PostgreSQL:
--    \copy customers FROM '/path/customers.csv' WITH (FORMAT csv, HEADER true);
--
--  SQLite:
--    .mode csv
--    .import --skip 1 /path/customers.csv customers
--
--  Date columns are stored as text in DD-MM-YYYY format. To work with them as
--  real dates:
--    MySQL      : STR_TO_DATE(acquisition_date, '%d-%m-%Y')
--    PostgreSQL : TO_DATE(acquisition_date, 'DD-MM-YYYY')
--    SQLite     : substr(acquisition_date,7,4)||'-'||substr(acquisition_date,4,2)||'-'||substr(acquisition_date,1,2)
--
--  Some columns contain blanks or out-of-range values by design (e.g. blank
--  churn_date for active customers). If your import tool rejects empty values
--  for a numeric column, load that column as text first, then clean and cast.
--
--  NOTE ON DUPLICATES: customers.csv contains a small number of repeated
--  customer_id rows. The PRIMARY KEY above will reject them on load. Either
--  (a) load customers into a staging table with no primary key, remove the
--  duplicates, then insert into this table; or
--  (b) load with duplicates ignored:
--      MySQL  : LOAD DATA ... IGNORE INTO TABLE customers ...
--      SQLite : INSERT OR IGNORE ...
--  Removing the duplicates is itself one of the data-cleaning tasks.
-- ============================================================================
