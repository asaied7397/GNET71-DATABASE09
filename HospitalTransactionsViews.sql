USE Hospital;
GO


/* ============================================================
   Q1 — Commit a Patient Update
   ============================================================ */

BEGIN TRANSACTION;

UPDATE dbo.Patients
SET WardId = 2
WHERE Id = 1;

COMMIT TRANSACTION;

-- Verify
SELECT Id, Name, WardId
FROM dbo.Patients
WHERE Id = 1;
GO


/* ============================================================
   Q2 — Rollback a Consultant Salary Update
   ============================================================ */

-- Salary before update
SELECT Id, Name, Salary
FROM dbo.Consultants
WHERE Id = 1;

BEGIN TRANSACTION;

UPDATE dbo.Consultants
SET Salary = Salary + 5000
WHERE Id = 1;

-- Salary inside transaction
SELECT Id, Name, Salary
FROM dbo.Consultants
WHERE Id = 1;

ROLLBACK TRANSACTION;

-- Salary after rollback
SELECT Id, Name, Salary
FROM dbo.Consultants
WHERE Id = 1;
GO


/* ============================================================
   Q3 — Commit Multiple Related Updates
   ============================================================ */

BEGIN TRY

    BEGIN TRANSACTION;

    -- Move patient to ward 3
    UPDATE dbo.Patients
    SET WardId = 3
    WHERE Id = 1;

    IF @@ROWCOUNT = 0
        THROW 50001, 'Patient not found.', 1;

    -- Move nurse to ward 3
    UPDATE dbo.Nurses
    SET ServesInWardId = 3
    WHERE Number = 1;

    IF @@ROWCOUNT = 0
        THROW 50002, 'Nurse not found.', 1;

    COMMIT TRANSACTION;

    PRINT 'Both updates committed successfully.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO

-- Verify
SELECT Id, Name, WardId
FROM dbo.Patients
WHERE Id = 1;

SELECT Number, Name, ServesInWardId
FROM dbo.Nurses
WHERE Number = 1;
GO


/* ============================================================
   Q4 — Use a Savepoint
   ============================================================ */

BEGIN TRANSACTION;

-- First update: change ward
UPDATE dbo.Patients
SET WardId = 2
WHERE Id = 1;

-- Create savepoint
SAVE TRANSACTION PatientUpdate;

-- Second update: temporary name
UPDATE dbo.Patients
SET Name = 'Temporary Patient Name'
WHERE Id = 1;

-- Rollback only the name change
ROLLBACK TRANSACTION PatientUpdate;

-- Commit the ward change
COMMIT TRANSACTION;

-- Verify
SELECT Id, Name, WardId
FROM dbo.Patients
WHERE Id = 1;
GO


/* ============================================================
   Q5 — Transaction with TRY/CATCH
   ============================================================ */

BEGIN TRY

    BEGIN TRANSACTION;

    UPDATE dbo.Consultants
    SET Salary = Salary + 3000
    WHERE Id = 1;

    IF @@ROWCOUNT = 0
        THROW 50003, 'Consultant not found.', 1;

    COMMIT TRANSACTION;

    PRINT 'Salary updated successfully.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO

-- Verify
SELECT Id, Name, Salary
FROM dbo.Consultants
WHERE Id = 1;
GO


/* ============================================================
   Q6 — Consultant Patient Statistics
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_ConsultantPatientStatistics
AS

SELECT
    c.Id AS ConsultantId,
    c.Name AS ConsultantName,
    c.Salary,
    COUNT(pca.PatientId) AS PatientCount

FROM dbo.Consultants c

LEFT JOIN dbo.PatientConsultantAssignments pca
    ON c.Id = pca.ConsultantId

GROUP BY
    c.Id,
    c.Name,
    c.Salary;
GO

-- Test
SELECT *
FROM dbo.vw_ConsultantPatientStatistics;
GO


/* ============================================================
   Q7 — Consultants with More Than 5 Patients
   ============================================================ */

SELECT
    ConsultantId,
    ConsultantName,
    Salary,
    PatientCount

FROM dbo.vw_ConsultantPatientStatistics

WHERE PatientCount > 5;
GO


/* ============================================================
   Q8 — Create an Indexed Aggregate View

   Requirements:
   - WITH SCHEMABINDING
   - COUNT_BIG(*)
   - GROUP BY
   - UNIQUE CLUSTERED INDEX

   Note:
   This view counts assignment rows per consultant.
   ============================================================ */

-- Required SET options for indexed views
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO

-- Drop existing indexed view if needed
DROP VIEW IF EXISTS dbo.vw_IndexedConsultantPatientCount;
GO

CREATE VIEW dbo.vw_IndexedConsultantPatientCount
WITH SCHEMABINDING
AS

SELECT
    ConsultantId,
    COUNT_BIG(*) AS PatientCount

FROM dbo.PatientConsultantAssignments

GROUP BY ConsultantId;
GO

-- Required unique clustered index
CREATE UNIQUE CLUSTERED INDEX
    IX_vw_IndexedConsultantPatientCount

ON dbo.vw_IndexedConsultantPatientCount
    (ConsultantId);
GO

-- Test
SELECT *
FROM dbo.vw_IndexedConsultantPatientCount;
GO


/* ============================================================
   Q9 — Query the Indexed Aggregate View
   ============================================================ */

SELECT
    v.ConsultantId,
    c.Name AS ConsultantName,
    v.PatientCount

FROM dbo.vw_IndexedConsultantPatientCount v

INNER JOIN dbo.Consultants c
    ON v.ConsultantId = c.Id

WHERE v.PatientCount > 5

ORDER BY v.PatientCount DESC;
GO


/* ============================================================
   Q10 — Display All Views
   ============================================================ */

SELECT
    name AS ViewName,
    create_date AS CreationDate,
    modify_date AS ModificationDate

FROM sys.views

ORDER BY name;
GO


/* ============================================================
   Q11 — Display a View Definition

   View: vw_PatientInformation

   First create it if it does not exist.
   ============================================================ */

IF OBJECT_ID('dbo.vw_PatientInformation', 'V') IS NULL
BEGIN
    EXEC
    (
        'CREATE VIEW dbo.vw_PatientInformation
         AS
         SELECT
             Id AS PatientId,
             Name AS PatientName,
             DOB,
             WardId
         FROM dbo.Patients'
    );
END;
GO

-- Display definition
EXEC sp_helptext 'dbo.vw_PatientInformation';
GO


/* ============================================================
   Q12 — Alter a View

   Return only:
   - Patient ID
   - Patient Name
   - DOB
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_PatientInformation
AS

SELECT
    Id AS PatientId,
    Name AS PatientName,
    DOB

FROM dbo.Patients;
GO

-- Test
SELECT *
FROM dbo.vw_PatientInformation;
GO


/* ============================================================
   Q13 — Drop a View

   Remove vw_ConsultantSalary.
   ============================================================ */

DROP VIEW IF EXISTS dbo.vw_ConsultantSalary;
GO


/* ============================================================
   Q14 — Patient Hospital Report

   LEFT JOIN ensures patients remain visible
   even without a ward or consultant.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_PatientHospitalReport
AS

SELECT
    p.Id AS PatientId,
    p.Name AS PatientName,
    p.DOB,

    w.Name AS WardName,

    c.Name AS ConsultantName

FROM dbo.Patients p

LEFT JOIN dbo.Wards w
    ON p.WardId = w.Id

LEFT JOIN dbo.PatientConsultantAssignments pca
    ON p.Id = pca.PatientId

LEFT JOIN dbo.Consultants c
    ON pca.ConsultantId = c.Id;
GO

-- Test
SELECT *
FROM dbo.vw_PatientHospitalReport;
GO


/* ============================================================
   Q15 — Search the Hospital Report

   Display patients who have a consultant.
   ============================================================ */

SELECT
    PatientId,
    PatientName,
    DOB,
    WardName,
    ConsultantName

FROM dbo.vw_PatientHospitalReport

WHERE ConsultantName IS NOT NULL;
GO


/* ============================================================
   Q16 — Display Patients by Ward

   Example: Ward 1

   Filter using WardName because the view
   contains WardName rather than WardId.
   ============================================================ */

DECLARE @WardName NVARCHAR(255);

SELECT @WardName = Name
FROM dbo.Wards
WHERE Id = 1;

SELECT
    PatientName,
    WardName,
    ConsultantName

FROM dbo.vw_PatientHospitalReport

WHERE WardName = @WardName;
GO


/* ============================================================
   Q17 — Most Patients per Consultant

   TOP 1 WITH TIES handles multiple consultants
   sharing the highest patient count.
   ============================================================ */

SELECT TOP 1 WITH TIES
    ConsultantId,
    ConsultantName,
    Salary,
    PatientCount

FROM dbo.vw_ConsultantPatientStatistics

ORDER BY PatientCount DESC;
GO


/* ============================================================
   Q18 — View + Filtering

   Create vw_PatientAgeInformation if missing.

   Age calculation accounts for whether the birthday
   has occurred this year.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_PatientAgeInformation
AS

SELECT
    Id AS PatientId,
    Name AS PatientName,
    DOB,

    DATEDIFF(YEAR, DOB, GETDATE())
    -
    CASE
        WHEN DATEADD(
            YEAR,
            DATEDIFF(YEAR, DOB, GETDATE()),
            DOB
        ) > CAST(GETDATE() AS DATE)
        THEN 1
        ELSE 0
    END AS Age

FROM dbo.Patients;
GO

-- Patients older than 60
SELECT
    PatientId,
    PatientName,
    DOB,
    Age

FROM dbo.vw_PatientAgeInformation

WHERE Age > 60

ORDER BY Age DESC;
GO


/* ============================================================
   Q19 — View + Sorting

   Order consultants by patient count descending.
   ============================================================ */

SELECT
    ConsultantId,
    ConsultantName,
    Salary,
    PatientCount

FROM dbo.vw_ConsultantPatientStatistics

ORDER BY
    PatientCount DESC,
    ConsultantName ASC;
GO


/* ============================================================
   Q20 — View + Aggregation

   Create vw_PatientWardInformation if missing.

   Then count patients in each ward.
   ============================================================ */

CREATE OR ALTER VIEW dbo.vw_PatientWardInformation
AS

SELECT
    p.Id AS PatientId,
    p.Name AS PatientName,
    p.WardId,
    w.Name AS WardName

FROM dbo.Patients p

LEFT JOIN dbo.Wards w
    ON p.WardId = w.Id;
GO

SELECT
    WardId,
    WardName,
    COUNT(PatientId) AS PatientCount

FROM dbo.vw_PatientWardInformation

GROUP BY
    WardId,
    WardName

ORDER BY PatientCount DESC;
GO


/* ============================================================
   Q21 — Find Indexed Views

   Display:
   - Schema Name
   - View Name
   - Index Name
   - Index Type
   ============================================================ */

SELECT
    s.name AS SchemaName,
    v.name AS ViewName,
    i.name AS IndexName,
    i.type_desc AS IndexType

FROM sys.views v

INNER JOIN sys.schemas s
    ON v.schema_id = s.schema_id

INNER JOIN sys.indexes i
    ON v.object_id = i.object_id

WHERE
    i.index_id > 0
    AND i.is_hypothetical = 0

ORDER BY
    s.name,
    v.name,
    i.name;
GO


/* ============================================================
   FINAL VERIFICATION
   ============================================================ */

-- Check all views created
SELECT
    name AS ViewName,
    create_date,
    modify_date
FROM sys.views
WHERE name LIKE 'vw_%'
ORDER BY name;
GO

-- Check consultant statistics
SELECT *
FROM dbo.vw_ConsultantPatientStatistics;
GO

-- Check indexed view
SELECT *
FROM dbo.vw_IndexedConsultantPatientCount;
GO

-- Check patient report
SELECT *
FROM dbo.vw_PatientHospitalReport;
GO

-- Check patient ages
SELECT *
FROM dbo.vw_PatientAgeInformation;
GO