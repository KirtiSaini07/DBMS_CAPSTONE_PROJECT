-- =====================================================
-- DBMS Capstone Project
-- Online Learning Platform with Adaptive Learning
-- Author: Kirti Saini
-- Database: MySQL 8.0 (tested in MySQL Workbench)
-- =====================================================
-- Note: the first line drops the database if it already exists,
-- so the script can be re-run from a clean state.
-- =====================================================

DROP DATABASE IF EXISTS online_learning_platform;

-- =====================================================
-- 1. DATABASE CREATION
-- =====================================================
CREATE DATABASE online_learning_platform;
USE online_learning_platform;

SHOW DATABASES;

-- =====================================================
-- 2. TABLE CREATION
-- =====================================================
CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(80) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    date_joined DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_student_name CHECK (CHAR_LENGTH(full_name) >= 2)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_title VARCHAR(120) NOT NULL,
    category VARCHAR(60) NOT NULL,
    difficulty ENUM('beginner','intermediate','advanced') NOT NULL DEFAULT 'beginner',
    CONSTRAINT chk_course_title CHECK (CHAR_LENGTH(course_title) >= 3)
);

CREATE TABLE modules (
    module_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    module_title VARCHAR(120) NOT NULL,
    module_order INT NOT NULL,
    estimated_minutes INT NOT NULL DEFAULT 30,
    CONSTRAINT fk_modules_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE,
    CONSTRAINT uq_course_module_order UNIQUE (course_id, module_order),
    CONSTRAINT chk_module_order CHECK (module_order > 0),
    CONSTRAINT chk_module_minutes CHECK (estimated_minutes > 0)
);

CREATE TABLE learning_paths (
    path_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    path_name VARCHAR(100) NOT NULL,
    target_level ENUM('beginner','intermediate','advanced') NOT NULL,
    CONSTRAINT fk_paths_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE,
    CONSTRAINT uq_course_path UNIQUE (course_id, path_name)
);

CREATE TABLE learning_path_modules (
    path_id INT NOT NULL,
    module_id INT NOT NULL,
    sequence_no INT NOT NULL,
    prerequisite_module_id INT NULL,
    PRIMARY KEY (path_id, module_id),
    CONSTRAINT uq_path_sequence UNIQUE (path_id, sequence_no),
    CONSTRAINT fk_lpm_path FOREIGN KEY (path_id)
        REFERENCES learning_paths(path_id) ON DELETE CASCADE,
    CONSTRAINT fk_lpm_module FOREIGN KEY (module_id)
        REFERENCES modules(module_id) ON DELETE CASCADE,
    CONSTRAINT fk_lpm_prerequisite FOREIGN KEY (prerequisite_module_id)
        REFERENCES modules(module_id) ON DELETE SET NULL,
    CONSTRAINT chk_lpm_sequence CHECK (sequence_no > 0)
);

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enrolled_on DATE NOT NULL DEFAULT (CURRENT_DATE),
    status ENUM('active','completed','cancelled') NOT NULL DEFAULT 'active',
    -- course_id for active rows, NULL otherwise (UNIQUE ignores NULLs)
    active_course_id INT GENERATED ALWAYS AS
        (CASE WHEN status = 'active' THEN course_id ELSE NULL END) VIRTUAL,
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enroll_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE,
    INDEX idx_enroll_student_course (student_id, course_id),
    UNIQUE INDEX uq_one_active_enrollment (student_id, active_course_id)
);

CREATE TABLE module_progress (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    module_id INT NOT NULL,
    status ENUM('not_started','in_progress','completed') NOT NULL DEFAULT 'not_started',
    completed_at DATETIME NULL,
    CONSTRAINT fk_progress_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_progress_module FOREIGN KEY (module_id)
        REFERENCES modules(module_id) ON DELETE CASCADE,
    CONSTRAINT uq_student_module UNIQUE (student_id, module_id),
    CONSTRAINT chk_completed_at CHECK (
        (status = 'completed' AND completed_at IS NOT NULL)
        OR (status <> 'completed' AND completed_at IS NULL))
);

CREATE TABLE assessments (
    assessment_id INT PRIMARY KEY AUTO_INCREMENT,
    module_id INT NOT NULL,
    assessment_title VARCHAR(120) NOT NULL,
    max_score DECIMAL(6,2) NOT NULL DEFAULT 100,
    CONSTRAINT fk_assess_module FOREIGN KEY (module_id)
        REFERENCES modules(module_id) ON DELETE CASCADE,
    CONSTRAINT chk_max_score CHECK (max_score > 0)
);

CREATE TABLE assessment_attempts (
    attempt_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    assessment_id INT NOT NULL,
    attempt_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    score DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_attempt_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_attempt_assessment FOREIGN KEY (assessment_id)
        REFERENCES assessments(assessment_id) ON DELETE CASCADE,
    CONSTRAINT chk_score_range CHECK (score >= 0 AND score <= 100),
    INDEX idx_attempt_student_assessment_date
        (student_id, assessment_id, attempt_date)
);

-- =====================================================
-- 3. SAMPLE DATA
-- =====================================================
INSERT INTO students (student_id, full_name, email, date_joined) VALUES
(1,'Wen Yifan','yifan@gmail.com','2026-01-02'),
(2,'Sang Yan','sang8@gmail.com','2026-01-04'),
(3,'Sang Zhi','zhizhi@gmail.com','2026-01-06'),
(4,'Duan Jiaxu','jiaxu123@gmail.com','2026-01-08');

INSERT INTO courses (course_id, course_title, category, difficulty) VALUES
(1,'SQL and Database Fundamentals','Computer Science','beginner'),
(2,'Python for Data Analysis','Data Science','intermediate');

INSERT INTO modules (module_id,course_id,module_title,module_order,estimated_minutes) VALUES
(101,1,'Introduction to Databases',1,30),
(102,1,'SQL Queries',2,45),
(103,1,'Joins and Relationships',3,50),
(104,1,'Indexes and Optimization',4,40),
(201,2,'Python Basics',1,45),
(202,2,'Working with Pandas',2,60);

INSERT INTO learning_paths (path_id,course_id,path_name,target_level) VALUES
(1,1,'SQL Starter Path','beginner'),
(2,1,'SQL Advanced Path','advanced'),
(3,2,'Python Data Path','intermediate');

INSERT INTO learning_path_modules (path_id,module_id,sequence_no,prerequisite_module_id) VALUES
(1,101,1,NULL),(1,102,2,101),(1,103,3,102),(1,104,4,103),
(2,101,1,NULL),(2,102,2,101),(2,103,3,102),(2,104,4,103),
(3,201,1,NULL),(3,202,2,201);

INSERT INTO enrollments (enrollment_id,student_id,course_id,enrolled_on,status) VALUES
(1,1,1,'2026-02-01','active'),
(2,2,1,'2026-02-02','active'),
(3,3,1,'2026-02-03','active'),
(4,1,2,'2026-02-04','active');

INSERT INTO module_progress (student_id,module_id,status,completed_at) VALUES
(1,101,'completed','2026-02-05 10:00:00'),
(1,102,'completed','2026-02-08 10:00:00'),
(1,103,'in_progress',NULL),
(1,201,'completed','2026-02-09 10:00:00'),
(2,101,'completed','2026-02-06 11:00:00'),
(2,102,'in_progress',NULL),
(3,101,'completed','2026-02-06 09:00:00'),
(3,102,'completed','2026-02-07 09:00:00'),
(3,103,'completed','2026-02-08 09:00:00'),
(3,104,'completed','2026-02-09 09:00:00');

INSERT INTO assessments (assessment_id,module_id,assessment_title,max_score) VALUES
(1001,101,'Database Basics Quiz',100),
(1002,102,'SQL Queries Quiz',100),
(1003,103,'Joins Quiz',100),
(1004,104,'Indexing Quiz',100);

INSERT INTO assessment_attempts (attempt_id,student_id,assessment_id,attempt_date,score) VALUES
(1,1,1001,'2026-02-05 12:00:00',70),
(2,1,1001,'2026-02-06 12:00:00',85),
(3,1,1002,'2026-02-07 12:00:00',90),
(4,1,1002,'2026-02-08 12:00:00',75),
(5,2,1001,'2026-02-05 13:00:00',80),
(6,2,1001,'2026-02-07 13:00:00',88),
(7,2,1002,'2026-02-08 13:00:00',92),
(8,3,1001,'2026-02-06 14:00:00',95),
(9,3,1002,'2026-02-07 14:00:00',96),
(10,3,1003,'2026-02-08 14:00:00',98),
(11,3,1004,'2026-02-09 14:00:00',94);

-- =====================================================
-- 4. VIEWS
-- =====================================================
-- Student progress view (read-only: uses joins, GROUP BY and aggregates)
CREATE OR REPLACE VIEW vw_student_progress AS
SELECT
    e.student_id,
    e.course_id,
    s.full_name,
    c.course_title,
    COUNT(DISTINCT CASE WHEN mp.status = 'completed' THEN m.module_id END) AS modules_completed,
    ROUND(AVG(aa.score),2) AS average_score,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN mp.status = 'completed' THEN m.module_id END)
        / NULLIF(COUNT(DISTINCT m.module_id),0), 2
    ) AS completion_percentage
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
JOIN modules m ON m.course_id = e.course_id
LEFT JOIN module_progress mp
    ON mp.student_id = e.student_id AND mp.module_id = m.module_id
LEFT JOIN assessments a ON a.module_id = m.module_id
LEFT JOIN assessment_attempts aa
    ON aa.student_id = e.student_id AND aa.assessment_id = a.assessment_id
WHERE e.status = 'active'
GROUP BY e.student_id, e.course_id, s.full_name, c.course_title;

-- Next-module recommendation view (read-only: uses EXISTS / NOT EXISTS)
CREATE OR REPLACE VIEW vw_next_module_recommendations AS
SELECT
    e.student_id,
    s.full_name,
    e.course_id,
    lp.path_id,
    lp.path_name,
    m.module_id AS recommended_module_id,
    m.module_title AS next_module,
    lpm.sequence_no
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN learning_paths lp ON lp.course_id = e.course_id
JOIN learning_path_modules lpm ON lpm.path_id = lp.path_id
JOIN modules m ON m.module_id = lpm.module_id
LEFT JOIN module_progress current_mp
    ON current_mp.student_id = e.student_id
   AND current_mp.module_id = m.module_id
WHERE e.status = 'active'
  AND (current_mp.status IS NULL OR current_mp.status <> 'completed')
  AND (
      lpm.prerequisite_module_id IS NULL
      OR EXISTS (
          SELECT 1
          FROM module_progress prerequisite_mp
          WHERE prerequisite_mp.student_id = e.student_id
            AND prerequisite_mp.module_id = lpm.prerequisite_module_id
            AND prerequisite_mp.status = 'completed'
      )
  )
  AND NOT EXISTS (
      SELECT 1
      FROM learning_path_modules earlier
      LEFT JOIN module_progress earlier_mp
        ON earlier_mp.student_id = e.student_id
       AND earlier_mp.module_id = earlier.module_id
      WHERE earlier.path_id = lpm.path_id
        AND earlier.sequence_no < lpm.sequence_no
        AND (earlier_mp.status IS NULL OR earlier_mp.status <> 'completed')
  );

-- =====================================================
-- 5. BASIC QUERIES
-- =====================================================
-- Q1. Display all students
SELECT student_id, full_name, email FROM students ORDER BY student_id;

-- Q2. Courses and their modules
SELECT c.course_title, m.module_order, m.module_title
FROM courses c
JOIN modules m ON m.course_id = c.course_id
ORDER BY c.course_id, m.module_order;

-- =====================================================
-- 6. CONSTRAINT DEMONSTRATIONS (these are EXPECTED to fail)
-- =====================================================
-- They are commented out so the script runs without stopping.
-- Remove the '-- ' before a statement to run it and see the error.

-- Q3. UNIQUE constraint -> Error 1062 (duplicate email)
-- INSERT INTO students(full_name,email) VALUES ('Wen Yifan Duplicate','yifan@gmail.com');

-- Q4. CHECK constraint -> Error 3819 (score above 100)
-- INSERT INTO assessment_attempts(student_id,assessment_id,score) VALUES (1,1001,120);

-- Q5. Unique active enrollment -> Error 1062 (uq_one_active_enrollment)
-- INSERT INTO enrollments(student_id,course_id,status) VALUES (1,1,'active');

-- =====================================================
-- 7. VIEW QUERIES
-- =====================================================
-- Q6. Student progress
SELECT * FROM vw_student_progress ORDER BY course_id, student_id;

-- Q7. Next recommended module
SELECT student_id, full_name, path_name, next_module
FROM vw_next_module_recommendations
ORDER BY student_id, path_id;

-- =====================================================
-- 8. WINDOW FUNCTION QUERIES
-- =====================================================
-- Q8. RANK() students within each course
WITH student_course_scores AS (
    SELECT e.course_id, e.student_id, s.full_name, AVG(aa.score) AS avg_score
    FROM enrollments e
    JOIN students s ON s.student_id = e.student_id
    JOIN modules m ON m.course_id = e.course_id
    JOIN assessments a ON a.module_id = m.module_id
    JOIN assessment_attempts aa
        ON aa.assessment_id = a.assessment_id AND aa.student_id = e.student_id
    WHERE e.status = 'active'
    GROUP BY e.course_id, e.student_id, s.full_name
)
SELECT course_id, student_id, full_name, ROUND(avg_score,2) AS average_score,
       RANK() OVER (PARTITION BY course_id ORDER BY avg_score DESC) AS course_rank
FROM student_course_scores
ORDER BY course_id, course_rank;

-- Q9. LAG() to find score drops
WITH ordered_attempts AS (
    SELECT aa.student_id, s.full_name, aa.assessment_id, a.assessment_title,
           aa.attempt_date, aa.score,
           LAG(aa.score) OVER (
               PARTITION BY aa.student_id, aa.assessment_id
               ORDER BY aa.attempt_date, aa.attempt_id
           ) AS previous_score,
           ROW_NUMBER() OVER (
               PARTITION BY aa.student_id, aa.assessment_id
               ORDER BY aa.attempt_date DESC, aa.attempt_id DESC
           ) AS recency_rank
    FROM assessment_attempts aa
    JOIN students s ON s.student_id = aa.student_id
    JOIN assessments a ON a.assessment_id = aa.assessment_id
)
SELECT student_id, full_name, assessment_title, previous_score, score AS latest_score
FROM ordered_attempts
WHERE recency_rank = 1 AND score < previous_score
ORDER BY student_id, assessment_id;

-- Q10. Running average per student
SELECT student_id, attempt_id, attempt_date, score,
       ROUND(AVG(score) OVER (
           PARTITION BY student_id
           ORDER BY attempt_date, attempt_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ),2) AS running_average
FROM assessment_attempts
ORDER BY student_id, attempt_date, attempt_id;

-- Q11. NTILE(3) learner levels
WITH learner_averages AS (
    SELECT s.student_id, s.full_name, AVG(aa.score) AS avg_score
    FROM students s
    JOIN assessment_attempts aa ON aa.student_id = s.student_id
    GROUP BY s.student_id, s.full_name
),
learner_bands AS (
    SELECT student_id, full_name, avg_score,
           NTILE(3) OVER (ORDER BY avg_score) AS performance_tile
    FROM learner_averages
)
SELECT student_id, full_name, ROUND(avg_score,2) AS average_score,
       CASE performance_tile
           WHEN 1 THEN 'Beginner'
           WHEN 2 THEN 'Intermediate'
           WHEN 3 THEN 'Advanced'
       END AS adaptive_level
FROM learner_bands
ORDER BY performance_tile, student_id;

-- Q12. Personalized path recommendation
WITH learner_averages AS (
    SELECT student_id, AVG(score) AS avg_score
    FROM assessment_attempts
    GROUP BY student_id
),
learner_levels AS (
    SELECT student_id,
           CASE NTILE(3) OVER (ORDER BY avg_score)
               WHEN 1 THEN 'beginner'
               WHEN 2 THEN 'intermediate'
               WHEN 3 THEN 'advanced'
           END AS adaptive_level
    FROM learner_averages
),
ranked_paths AS (
    SELECT e.student_id, e.course_id, ll.adaptive_level,
           lp.path_id, lp.path_name,
           ROW_NUMBER() OVER (
               PARTITION BY e.student_id, e.course_id
               ORDER BY (lp.target_level = ll.adaptive_level) DESC, lp.path_id
           ) AS choice_no
    FROM enrollments e
    JOIN learner_levels ll ON ll.student_id = e.student_id
    JOIN learning_paths lp ON lp.course_id = e.course_id
    WHERE e.status = 'active'
)
SELECT student_id, course_id, adaptive_level, path_name AS recommended_path
FROM ranked_paths
WHERE choice_no = 1
ORDER BY student_id, course_id;


-- =====================================================
-- 9. INDEXING AND QUERY PLANS
-- =====================================================
-- Q13. Uses idx_enroll_student_course
EXPLAIN
SELECT enrollment_id, status
FROM enrollments
WHERE student_id = 1 AND course_id = 1;

-- Q14. Uses idx_attempt_student_assessment_date (no filesort)
EXPLAIN
SELECT attempt_id, score, attempt_date
FROM assessment_attempts
WHERE student_id = 1 AND assessment_id = 1002
ORDER BY attempt_date;

-- Q15. No usable index -> full table scan (type = ALL)
EXPLAIN
SELECT attempt_id, student_id, assessment_id, score
FROM assessment_attempts
WHERE score >= 90;

-- Q16. Show indexes
SHOW INDEX FROM enrollments;
SHOW INDEX FROM assessment_attempts;


-- =====================================================
-- 10. EXTRA QUERIES
-- =====================================================
-- Q17. Completed modules per student
SELECT s.full_name, COUNT(mp.module_id) AS completed_modules
FROM students s
LEFT JOIN module_progress mp
  ON mp.student_id = s.student_id AND mp.status = 'completed'
GROUP BY s.student_id, s.full_name
ORDER BY s.student_id;

-- Q18. Students with incomplete courses
SELECT s.full_name, c.course_title,
       COUNT(DISTINCT CASE WHEN mp.status='completed' THEN m.module_id END) AS completed,
       COUNT(DISTINCT m.module_id) AS total_modules
FROM enrollments e
JOIN students s ON s.student_id=e.student_id
JOIN courses c ON c.course_id=e.course_id
JOIN modules m ON m.course_id=e.course_id
LEFT JOIN module_progress mp
  ON mp.student_id=e.student_id AND mp.module_id=m.module_id
WHERE e.status='active'
GROUP BY s.student_id,s.full_name,c.course_id,c.course_title
HAVING completed < total_modules;
