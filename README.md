# Online Learning Platform with Adaptive Learning
 
DBMS capstone project
 
This is a MySQL database for an online learning platform that adjusts to each student. It stores students, courses, modules, learning paths, enrollments, quizzes and quiz attempts. Using SQL queries on this data, the system can:
 
- show each student's progress in a course
- suggest the next module a student should study
- rank students and spot when a score drops
- group students into Beginner, Intermediate and Advanced levels and suggest a learning path for them
## Tech used
 
- MySQL 8.0
- MySQL Workbench
## Database design
 
| Table | What it stores |
|---|---|
| `students` | Learners signed up on the platform |
| `courses` | Courses with their difficulty level |
| `modules` | Chapters of a course, in order |
| `learning_paths` | Learning paths, each aimed at one skill level |
| `learning_path_modules` | Modules in each path, their order and prerequisite |
| `enrollments` | Which student joined which course, and its status |
| `module_progress` | How far each student has got in each module |
| `assessments` | A quiz linked to a module |
| `assessment_attempts` | Each quiz attempt with score and date |
 
**Relationships**
 
- One course has many modules and many learning paths (1:N).
- Students and courses are M:N, connected through `enrollments`.
- Learning paths and modules are M:N, connected through `learning_path_modules`.
## What the project covers
 
- **Constraints:** PRIMARY KEY, FOREIGN KEY (with `ON DELETE CASCADE` / `SET NULL`), NOT NULL, UNIQUE, CHECK, DEFAULT and ENUM
- **Generated column:** `enrollments.active_course_id` holds the course_id only when the enrollment is active. A UNIQUE index on `(student_id, active_course_id)` stops a student from having two active enrollments in the same course, while cancelled or completed rows are still allowed.
- **Views:** `vw_student_progress` and `vw_next_module_recommendations`
- **Window functions:** `RANK()`, `LAG()`, running average with `AVG() OVER (...)`, and `NTILE(3)`
- **Indexing:** composite indexes checked with `EXPLAIN`, compared with a query that has to do a full table scan
## How to run
 
1. Clone this repo or download `online_learning_platform.sql`.
2. Open the file in MySQL Workbench (or any MySQL 8.0 client).
3. Run the whole script.
The script creates the database `online_learning_platform`, builds all tables, adds the sample data, creates the views and then runs every query.
 
> **Note:** the first line is `DROP DATABASE IF EXISTS online_learning_platform;` so the script can be re-run from scratch. Don't run it if you already have a database with this name that you want to keep.
 
From the command line:
 
```bash
mysql -u root -p < online_learning_platform.sql
```
 
## Queries included
 
| No. | Query | Concept |
|---|---|---|
| Q1 | Display all students | SELECT |
| Q2 | Courses and their modules | JOIN |
| Q3 | Duplicate email insert | UNIQUE (expected error 1062) |
| Q4 | Score above 100 | CHECK (expected error 3819) |
| Q5 | Second active enrollment in the same course | UNIQUE on generated column (expected error 1062) |
| Q6 | Student progress | View |
| Q7 | Next recommended module | View with EXISTS / NOT EXISTS |
| Q8 | Rank students in each course | RANK() |
| Q9 | Students whose latest score dropped | LAG() |
| Q10 | Running average per student | AVG() OVER with window frame |
| Q11 | Learner levels | NTILE(3) |
| Q12 | Personalized path recommendation | NTILE + ROW_NUMBER() |
| Q13 | Enrollment lookup plan | EXPLAIN (uses index) |
| Q14 | Attempt lookup plan | EXPLAIN (uses index, no filesort) |
| Q15 | Filter on score only | EXPLAIN (full table scan) |
| Q16 | List indexes | SHOW INDEX |
| Q17 | Completed modules per student | LEFT JOIN + COUNT |
| Q18 | Students with incomplete courses | GROUP BY + HAVING |
 
Q3, Q4 and Q5 are meant to fail, so they are commented out in the script. Uncomment one to see the error.
 
## Files
 
```
online_learning_platform.sql   full script: database, tables, data, views and queries
README.md                      this file
```
