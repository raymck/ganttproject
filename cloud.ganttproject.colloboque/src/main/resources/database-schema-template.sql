
CREATE SCHEMA project_model_metadata;
SET search_path TO project_model_metadata;
CREATE TYPE TaskIntPropertyName AS ENUM ('completion', 'priority');
CREATE TYPE TaskTextPropertyName AS ENUM ('priority', 'color', 'shape', 'web_link', 'notes');


----------------------------------------------------------------------------------------------------------------
-- This template schema is cloned for every "branch" of the project.

CREATE SCHEMA project_template;
SET search_path TO project_template;

-- Basic task data
CREATE TABLE TaskName(
                         uid TEXT PRIMARY KEY,
                         num INT NOT NULL,
                         name TEXT NOT NULL DEFAULT ''
);
-- Task start date and duration shall be changed as a whole
CREATE TABLE TaskDates(
                          uid           TEXT PRIMARY KEY REFERENCES TaskName,
                          start_date    DATE NOT NULL,
                          duration_days INT NOT NULL DEFAULT 1,
                          earliest_start_date DATE
);

-- Other task properties can be changed independently, so they are stored in rows, one row corresponds to one
-- instance of the task property value

-- Integer valued properties
CREATE TABLE TaskIntProperties(
                                  uid        TEXT REFERENCES TaskName,
                                  prop_name  project_model_metadata.TaskIntPropertyName,
                                  prop_value INT,
                                  PRIMARY KEY(uid, prop_name)
);

-- Text valued properties
CREATE TABLE TaskTextProperties(
                                   uid TEXT REFERENCES TaskName,
                                   prop_name project_model_metadata.TaskTextPropertyName,
                                   prop_value TEXT,
                                   PRIMARY KEY(uid, prop_name)
);

CREATE TABLE TaskCostProperties(
                                   uid TEXT REFERENCES TaskName PRIMARY KEY,
                                   is_cost_calculated BOOLEAN,
                                   cost_manual_value NUMERIC
);

CREATE TABLE TaskClassProperties(
                                    uid TEXT REFERENCES TaskName PRIMARY KEY,
                                    is_milestone BOOLEAN NOT NULL DEFAULT false,
                                    is_project_task BOOLEAN NOT NULL DEFAULT false
);

-- Updatable view which collects all task properties in a single row. Inserts and updates are processed
-- with INSTEAD OF triggers.
CREATE VIEW Task AS
SELECT TaskName.uid,
       num,
       name,
       start_date,
       duration_days AS duration,
       earliest_start_date,
       is_cost_calculated,
       cost_manual_value,
       is_milestone,
       is_project_task,
       MAX(TIP.prop_value) FILTER (WHERE TIP.prop_name = 'completion') AS completion,
       MAX(TTP.prop_value) FILTER (WHERE TTP.prop_name = 'priority') AS priority,
       MAX(TTP.prop_value) FILTER (WHERE TTP.prop_name = 'color') AS color,
       MAX(TTP.prop_value) FILTER (WHERE TTP.prop_name = 'shape') AS shape,
       MAX(TTP.prop_value) FILTER (WHERE TTP.prop_name = 'web_link') AS web_link,
       MAX(TTP.prop_value) FILTER (WHERE TTP.prop_name = 'notes') AS notes
from      TaskName
              JOIN      TaskDates USING(uid)
              LEFT JOIN TaskIntProperties TIP USING(uid)
              LEFT JOIN TaskTextProperties TTP USING(uid)
              LEFT JOIN TaskCostProperties TCP USING(uid)
              LEFT JOIN TaskClassProperties TCLP USING(uid)
GROUP BY TaskName.uid, TaskDates.uid, TCP.uid, TCLP.uid;
