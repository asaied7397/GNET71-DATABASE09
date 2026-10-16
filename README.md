# Hospital Database — Transactions & Views

This assignment is part of the **ASP.NET Backend Development Course — SQL Server Module**.

It covers **21 SQL Server questions** focused on database transactions, error handling, views, indexed views, and data reporting using the `Hospital` database.

## Technologies Used

- Microsoft SQL Server
- T-SQL
- Docker
- Visual Studio Code
- MSSQL Extension

## Topics Covered

| Questions | Topic                              |
| --------- | ---------------------------------- |
| Q1–Q3     | Transactions, COMMIT & ROLLBACK    |
| Q4        | SAVEPOINT                          |
| Q5        | Transactions with TRY/CATCH        |
| Q6–Q7     | Views with JOINs and Aggregation   |
| Q8–Q9     | Indexed Views                      |
| Q10–Q13   | View Management                    |
| Q14–Q16   | Multi-Table Views and Filtering    |
| Q17–Q20   | Views with Sorting and Aggregation |
| Q21       | Finding Indexed Views              |

## 1. Database Transactions

Transactions ensure database operations are completed consistently.

Main commands:

- `BEGIN TRANSACTION` — Starts a transaction.
- `COMMIT` — Saves changes permanently.
- `ROLLBACK` — Cancels uncommitted changes.
- `SAVE TRANSACTION` — Creates a savepoint for partial rollback.

Example:

```sql
BEGIN TRANSACTION;

UPDATE Patients
SET WardId = 2
WHERE Id = 1;

COMMIT TRANSACTION;
```

The assignment also combines transactions with `TRY/CATCH` for error handling.

## 2. SQL Views

Views are reusable SQL queries that simplify data retrieval and reporting.

Examples created:

- `vw_ConsultantPatientStatistics`
- `vw_PatientInformation`
- `vw_PatientHospitalReport`
- `vw_PatientAgeInformation`
- `vw_PatientWardInformation`

Example:

```sql
CREATE VIEW dbo.vw_PatientInformation
AS
SELECT
    Id AS PatientId,
    Name AS PatientName,
    DOB
FROM dbo.Patients;
```

## 3. Indexed Views

Indexed views physically store indexed results to support query performance.

The assignment creates:

`vw_IndexedConsultantPatientCount`

Using:

- `WITH SCHEMABINDING`
- `COUNT_BIG(*)`
- `GROUP BY`
- `UNIQUE CLUSTERED INDEX`

Example:

```sql
CREATE UNIQUE CLUSTERED INDEX
IX_vw_IndexedConsultantPatientCount
ON dbo.vw_IndexedConsultantPatientCount(ConsultantId);
```

## 4. View Management

The assignment also practices:

- Creating and altering views
- Dropping views
- Displaying view definitions
- Retrieving view metadata
- Finding indexed views using system catalogs
- Filtering, sorting, and aggregating view results

## Project File

```text
Hospital_Transactions_Views.sql
```

Contains the solutions for all 21 questions.

## Key Learning Outcomes

- Managing transactions using COMMIT and ROLLBACK
- Using SAVEPOINT for partial rollbacks
- Handling transaction errors with TRY/CATCH
- Creating reusable SQL views
- Combining multiple tables using LEFT JOIN
- Using aggregation and filtering with views
- Creating indexed views with SCHEMABINDING
- Managing views through SQL Server system catalogs

---

**ASP.NET Backend Development Course — SQL Server Module**
