-- ========================================
-- DATABASE CREATION
-- ========================================
CREATE DATABASE FinalProject;
GO

USE FinalProject;
GO

-- ========================================
-- TABLE CREATION
-- ========================================
-- Regions Table
CREATE TABLE tbl_regions (
    id INT PRIMARY KEY,
    name VARCHAR(25) NOT NULL
);

-- Countries Table
CREATE TABLE tbl_countries (
    id CHAR(3) PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    region INT NOT NULL,
    CONSTRAINT FK_tbl_regions FOREIGN KEY (region) REFERENCES tbl_regions(id)
);

-- Locations Table
CREATE TABLE tbl_locations (
    id INT PRIMARY KEY,
    street_address VARCHAR(40),
    postal_code VARCHAR(12),
    city VARCHAR(30) NOT NULL,
    state_province VARCHAR(25),
    country CHAR(3) NOT NULL,
    CONSTRAINT FK_tbl_countries FOREIGN KEY (country) REFERENCES tbl_countries(id)
);

-- Departments Table
CREATE TABLE tbl_departments (
    id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    location INT NOT NULL,
    CONSTRAINT FK_tbl_locations FOREIGN KEY (location) REFERENCES tbl_locations(id)
);

-- Jobs Table
CREATE TABLE tbl_jobs (
    id VARCHAR(10) PRIMARY KEY,
    title VARCHAR(35) NOT NULL,
    min_salary INT,
    max_salary INT
);

-- Employees Table
CREATE TABLE tbl_employees (
    id INT PRIMARY KEY,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25),
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female')),
    email VARCHAR(25) NOT NULL UNIQUE,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    salary INT CHECK (salary >= 0 AND salary <= 1000000),
    manager INT,
    job VARCHAR(10) NOT NULL,
    department INT NOT NULL,
    CONSTRAINT FK_tbl_departments_employees FOREIGN KEY (department) REFERENCES tbl_departments(id),
    CONSTRAINT FK_tbl_jobs FOREIGN KEY (job) REFERENCES tbl_jobs(id),
    CONSTRAINT FK_tbl_employees_manager FOREIGN KEY (manager) REFERENCES tbl_employees(id)
);

-- Job Histories Table
CREATE TABLE tbl_job_histories (
    employee INT,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(10) NOT NULL,
    job VARCHAR(10) NOT NULL,
    department INT NOT NULL,
    PRIMARY KEY (employee, start_date),
    CONSTRAINT FK_tbl_employees FOREIGN KEY (employee) REFERENCES tbl_employees(id),
    CONSTRAINT FK_tbl_jobs_job_histories FOREIGN KEY (job) REFERENCES tbl_jobs(id),
    CONSTRAINT FK_tbl_departments FOREIGN KEY (department) REFERENCES tbl_departments(id)
);

-- Accounts Table
CREATE TABLE tbl_accounts (
    id INT PRIMARY KEY,
    username VARCHAR(25) NOT NULL,
    password VARCHAR(255) NOT NULL,
    otp INT NOT NULL,
    is_expired BIT NOT NULL,
    is_used DATETIME NOT NULL,
    CONSTRAINT FK_tbl_employees_accounts FOREIGN KEY (id) REFERENCES tbl_employees(id)
);

-- Roles Table
CREATE TABLE tbl_roles (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Account Roles Table
CREATE TABLE tbl_account_roles (
    id INT PRIMARY KEY,
    account INT NOT NULL,
    role INT NOT NULL,
    CONSTRAINT FK_tbl_accounts FOREIGN KEY (account) REFERENCES tbl_accounts(id),
    CONSTRAINT FK_tbl_roles FOREIGN KEY (role) REFERENCES tbl_roles(id)
);

-- Permissions Table
CREATE TABLE tbl_permissions (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Role Permissions Table
CREATE TABLE tbl_role_permissions (
    id INT PRIMARY KEY,
    role INT NOT NULL,
    permission INT NOT NULL,
    CONSTRAINT FK_tbl_roles_role_permissions FOREIGN KEY (role) REFERENCES tbl_roles(id),
    CONSTRAINT FK_tbl_permissions FOREIGN KEY (permission) REFERENCES tbl_permissions(id)
);

-- ========================================
-- STORED PROCEDURES
-- ========================================

-- SD-001: Procedure untuk login pengguna
CREATE PROCEDURE dbo.user_login
    @username VARCHAR(25),
    @password VARCHAR(255)
AS
BEGIN
    DECLARE @stored_password VARCHAR(255);
    DECLARE @is_expired BIT;
    DECLARE @is_used DATETIME;
    
    -- Mengambil data pengguna
    SELECT @stored_password = password, @is_expired = is_expired, @is_used = is_used
    FROM tbl_accounts WHERE username = @username;
    
    -- Validasi akun
    IF @is_expired = 1
        RAISERROR('Akun sudah kadaluarsa.', 16, 1);
    ELSE IF @is_used IS NOT NULL
        RAISERROR('Akun sudah digunakan.', 16, 1);
    ELSE IF @stored_password IS NULL OR @stored_password != HASHBYTES('SHA2_256', @password)
        RAISERROR('Username atau password salah.', 16, 1);
    ELSE
    BEGIN
        UPDATE tbl_accounts SET is_used = GETDATE() WHERE username = @username;
        SELECT 'Login berhasil' AS pesan;
    END
END;
GO
CREATE PROCEDURE dbo.user_login
    @username VARCHAR(25),
    @password VARCHAR(255)
AS
BEGIN
    DECLARE @stored_password VARCHAR(255);
    DECLARE @is_expired BIT;
    DECLARE @is_used DATETIME;
    
    -- Mengambil data pengguna
    SELECT @stored_password = password, @is_expired = is_expired, @is_used = is_used
    FROM tbl_accounts WHERE username = @username;
    
    -- Validasi akun
    IF @is_expired = 1
        RAISERROR('Akun sudah kadaluarsa.', 16, 1);
    ELSE IF @is_used IS NOT NULL
        RAISERROR('Akun sudah digunakan.', 16, 1);
    ELSE IF @stored_password IS NULL OR @stored_password != HASHBYTES('SHA2_256', @password)
        RAISERROR('Username atau password salah.', 16, 1);
    ELSE
    BEGIN
        UPDATE tbl_accounts SET is_used = GETDATE() WHERE username = @username;
        SELECT 'Login berhasil' AS pesan;
    END
END;
GO

-- SD-002: Procedure untuk reset password
CREATE PROCEDURE dbo.forgot_password
    @username VARCHAR(50),
    @new_password VARCHAR(255)
AS
BEGIN
    DECLARE @hashed_password VARBINARY(256);
    
    -- Memeriksa apakah username ada
    IF NOT EXISTS (SELECT 1 FROM tbl_accounts WHERE username = @username)
    BEGIN
        RAISERROR('Username tidak ditemukan.', 16, 1);
        RETURN;
    END
    
    -- Meng-hash password baru
    SET @hashed_password = HASHBYTES('SHA2_256', @new_password);
    
    -- Memperbarui password pengguna
    UPDATE tbl_accounts
    SET password = @hashed_password
    WHERE username = @username;
    
    -- Kembalikan pesan sukses
    SELECT 'Password berhasil direset.' AS message;
END;
GO

-- SD-003: Procedure untuk menambahkan karyawan baru
CREATE PROCEDURE dbo.add_employee
    @firstName VARCHAR(25),
    @lastName VARCHAR(25),
    @gender VARCHAR(10),
    @email VARCHAR(25),
    @phone VARCHAR(20) = NULL,
    @hireDate DATE,
    @salary INT = NULL,
    @managerId INT = NULL,
    @jobId VARCHAR(10),
    @departmentId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO tbl_employees (first_name, last_name, gender, email, phone, hire_date, salary, manager, job, department)
    VALUES (@firstName, @lastName, @gender, @email, @phone, @hireDate, @salary, @managerId, @jobId, @departmentId);
    
    PRINT 'Employee added successfully.';
END;
GO

-- SD-004: Procedure untuk memperbarui data karyawan
CREATE PROCEDURE dbo.edit_employee
    @employeeId INT,
    @firstName VARCHAR(25),
    @lastName VARCHAR(25),
    @gender VARCHAR(10),
    @email VARCHAR(25),
    @phone VARCHAR(20) = NULL,
    @hireDate DATE,
    @salary INT = NULL,
    @managerId INT = NULL,
    @jobId VARCHAR(10),
    @departmentId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM tbl_employees WHERE id = @employeeId)
    BEGIN
        PRINT 'Employee with ID ' + CAST(@employeeId AS VARCHAR) + ' does not exist.';
        RETURN;
    END
    
    UPDATE tbl_employees
    SET 
        first_name = @firstName,
        last_name = @lastName,
        gender = @gender,
        email = @email,
        phone = @phone,
        hire_date = @hireDate,
        salary = @salary,
        manager = @managerId,
        job = @jobId,
        department = @departmentId
    WHERE id = @employeeId;
    
    PRINT 'Employee details updated successfully.';
END;
GO

-- SD-005: Procedure untuk menghapus karyawan
CREATE PROCEDURE dbo.delete_employee
    @id INT
AS
BEGIN
    DELETE FROM tbl_employees
    WHERE id = @id;
END;
GO

-- SD-006: Procedure untuk menambahkan pekerjaan
CREATE PROCEDURE dbo.add_job
    @id VARCHAR(10),
    @title VARCHAR(35),
    @min_salary INT = NULL,
    @max_salary INT = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tbl_jobs WHERE id = @id)
    BEGIN
        RAISERROR('Job dengan ID tersebut sudah ada.', 16, 1);
        RETURN;
    END
    
    INSERT INTO tbl_jobs (id, title, min_salary, max_salary)
    VALUES (@id, @title, @min_salary, @max_salary);
    
    SELECT 'Data job berhasil ditambahkan.' AS message;
END;
GO

-- SD-007: Procedure untuk mengedit pekerjaan
CREATE PROCEDURE dbo.edit_job
    @id VARCHAR(10),
    @new_title VARCHAR(35),
    @new_min_salary INT = NULL,
    @new_max_salary INT = NULL
AS
BEGIN
    UPDATE tbl_jobs
    SET title = @new_title, min_salary = @new_min_salary, max_salary = @new_max_salary
    WHERE id = @id;
    
    SELECT 'Data job berhasil diperbarui.' AS message;
END;
GO

-- SD-008: Procedure untuk menghapus pekerjaan
CREATE PROCEDURE dbo.delete_job
    @id VARCHAR(10)
AS
BEGIN
    DELETE FROM tbl_jobs WHERE id = @id;
END;
GO

-- SD-009: Procedure untuk menambahkan departemen
CREATE PROCEDURE dbo.add_department
    @id INT,
    @name VARCHAR(30),
    @location INT
AS
BEGIN
    INSERT INTO tbl_departments (id, name, location)
    VALUES (@id, @name, @location);
    
    SELECT 'Department added successfully.' AS message;
END;
GO

-- SD-010: Procedure untuk mengedit departemen
CREATE PROCEDURE dbo.edit_department
    @id INT,
    @new_name VARCHAR(30),
    @new_location INT
AS
BEGIN
    UPDATE tbl_departments
    SET name = @new_name, location = @new_location
    WHERE id = @id;
    
    SELECT 'Data departemen berhasil diperbarui.' AS message;
END;
GO

-- SD-011: Procedure untuk menghapus departemen
CREATE PROCEDURE dbo.delete_department
    @id INT
AS
BEGIN
    DELETE FROM tbl_departments WHERE id = @id;
END;
GO

-- SD-012: Procedure untuk menambahkan lokasi
CREATE PROCEDURE dbo.add_location
    @id INT,
    @street_address VARCHAR(40),
    @postal_code VARCHAR(12),
    @city VARCHAR(30),
    @state_province VARCHAR(25),
    @country CHAR(3)
AS
BEGIN
    INSERT INTO tbl_locations (id, street_address, postal_code, city, state_province, country)
    VALUES (@id, @street_address, @postal_code, @city, @state_province, @country);
END;
GO

-- SD-013: Procedure untuk mengedit lokasi
CREATE PROCEDURE dbo.edit_location
    @id INT,
    @street_address VARCHAR(40),
    @postal_code VARCHAR(12),
    @city VARCHAR(30),
    @state_province VARCHAR(25),
    @country CHAR(3)
AS
BEGIN
    UPDATE tbl_locations
    SET street_address = @street_address,
        postal_code = @postal_code,
        city = @city,
        state_province = @state_province,
        country = @country
    WHERE id = @id;
END;
GO

-- SD-014: Procedure untuk menghapus lokasi
CREATE PROCEDURE dbo.delete_location
    @id INT
AS
BEGIN
    DELETE FROM tbl_locations WHERE id = @id;
END;
GO

-- SD-015: Procedure untuk menambahkan negara
CREATE PROCEDURE dbo.add_country
    @id CHAR(3),
    @name VARCHAR(40),
    @region INT
AS
BEGIN
    INSERT INTO tbl_countries (id, name, region)
    VALUES (@id, @name, @region);
END;
GO

-- SD-016: Procedure untuk mengedit negara
CREATE PROCEDURE dbo.edit_country
    @id CHAR(3),
    @name VARCHAR(40),
    @region INT
AS
BEGIN
    UPDATE tbl_countries
    SET name = @name, region = @region
    WHERE id = @id;
END;
GO

-- SD-017: Procedure untuk menghapus negara
CREATE PROCEDURE dbo.delete_country
    @id CHAR(3)
AS
BEGIN
    DELETE FROM tbl_countries WHERE id = @id;
END;
GO

-- SD-018: Procedure untuk menambahkan region
CREATE PROCEDURE dbo.add_region
    @id INT,
    @name VARCHAR(25)
AS
BEGIN
    INSERT INTO tbl_regions (id, name)
    VALUES (@id, @name);
    
    SELECT 'Region berhasil ditambahkan.' AS message;
END;
GO

-- SD-019: Procedure untuk mengedit region
CREATE PROCEDURE dbo.edit_region
    @id INT,
    @new_name VARCHAR(25)
AS
BEGIN
    UPDATE tbl_regions
    SET name = @new_name
    WHERE id = @id;
    
    SELECT 'Region berhasil diperbarui.' AS message;
END;
GO

-- SD-020: Procedure untuk menghapus region
CREATE PROCEDURE dbo.delete_region
    @id INT
AS
BEGIN
    DELETE FROM tbl_regions WHERE id = @id;
END;
GO

-- SD-021: Procedure untuk menambahkan role
CREATE PROCEDURE dbo.add_role
    @id INT,
    @name VARCHAR(50)
AS
BEGIN
    INSERT INTO tbl_roles (id, name)
    VALUES (@id, @name);
END;
GO

-- SD-022: Procedure untuk mengedit role
CREATE PROCEDURE dbo.edit_role
    @id INT,
    @new_name VARCHAR(50)
AS
BEGIN
    UPDATE tbl_roles
    SET name = @new_name
    WHERE id = @id;
END;
GO

-- SD-023: Procedure untuk menghapus role
CREATE PROCEDURE dbo.delete_role
    @id INT
AS
BEGIN
    DELETE FROM tbl_roles WHERE id = @id;
END;
GO

-- SD-024: Procedure untuk menambahkan permission
CREATE PROCEDURE dbo.add_permission
    @id INT,
    @name VARCHAR(100)
AS
BEGIN
    INSERT INTO tbl_permissions (id, name)
    VALUES (@id, @name);
END;
GO

-- SD-025: Procedure untuk mengedit permission
CREATE PROCEDURE dbo.edit_permission
    @id INT,
    @new_name VARCHAR(100)
AS
BEGIN
    UPDATE tbl_permissions
    SET name = @new_name
    WHERE id = @id;
END;
GO

-- SD-026: Procedure untuk menghapus permission
CREATE PROCEDURE dbo.delete_permission
    @id INT
AS
BEGIN
    DELETE FROM tbl_permissions WHERE id = @id;
END;
GO

-- SD-027: Procedure untuk mengedit profil pengguna
CREATE PROCEDURE dbo.edit_profile
    @id INT,
    @new_name VARCHAR(50),
    @new_email VARCHAR(100)
AS
BEGIN
    UPDATE tbl_accounts
    SET username = @new_name, email = @new_email
    WHERE id = @id;
    
    SELECT 'Profil berhasil diperbarui.' AS message;
END;
GO

-- SD-028: Procedure untuk mengubah password pengguna
CREATE PROCEDURE dbo.change_password
    @id INT,
    @current_password VARCHAR(255),
    @new_password VARCHAR(255)
AS
BEGIN
    DECLARE @stored_password VARCHAR(255);
    
    -- Ambil password saat ini
    SELECT @stored_password = password
    FROM tbl_accounts WHERE id = @id;
    
    -- Periksa kesesuaian password
    IF @stored_password IS NULL OR @stored_password != HASHBYTES('SHA2_256', @current_password)
    BEGIN
        RAISERROR('Password saat ini tidak sesuai.', 16, 1);
        RETURN;
    END
    
    -- Update password baru
    UPDATE tbl_accounts
    SET password = HASHBYTES('SHA2_256', @new_password)
    WHERE id = @id;
    
    SELECT 'Password berhasil diubah.' AS message;
END;
GO

-- SD-029: Procedure untuk menghasilkan OTP
CREATE PROCEDURE dbo.generate_otp
    @length INT = 6
AS
BEGIN
    DECLARE @otp VARCHAR(10);
    
    -- Generate angka acak sebagai OTP
    SET @otp = (
        SELECT CAST(CAST(NEWID() AS VARBINARY) AS INT) % POWER(10, @length)
    );
    
    SELECT @otp AS otp;
END;
GO


-- ========================================
-- VIEWS
-- ========================================

-- View untuk menampilkan detail karyawan
CREATE VIEW vw_employee_details AS
SELECT 
    e.id,
    a.username,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.gender,
    e.email,
    e.hire_date,
    e.salary,
    e.manager AS manager_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    e.job,
    d.name AS department,
    r.name AS role,
    l.city AS location,
    jh.status
FROM
    tbl_employees e
    LEFT JOIN tbl_accounts a ON e.id = a.id
    LEFT JOIN tbl_employees m ON e.manager = m.id
    LEFT JOIN tbl_departments d ON e.department = d.id
    LEFT JOIN tbl_locations l ON d.location = l.id
    LEFT JOIN tbl_account_roles ar ON a.id = ar.account
    LEFT JOIN tbl_roles r ON ar.role = r.id
    LEFT JOIN tbl_job_histories jh ON e.id = jh.employee;
GO

-- View untuk menampilkan daftar pekerjaan
CREATE VIEW vw_job_list AS
SELECT 
    id,
    title,
    min_salary,
    max_salary
FROM
    tbl_jobs;
GO

-- View untuk menampilkan daftar departemen
CREATE VIEW vw_department_list AS
SELECT 
    d.id,
    d.name,
    l.city AS location
FROM
    tbl_departments d
    LEFT JOIN tbl_locations l ON d.location = l.id;
GO

-- View untuk menampilkan daftar lokasi
CREATE VIEW vw_location_list AS
SELECT 
    id,
    street_address,
    postal_code,
    city,
    state_province,
    country
FROM
    tbl_locations;
GO

-- View untuk menampilkan daftar negara
CREATE VIEW vw_country_list AS
SELECT 
    c.id,
    c.name,
    r.name AS region
FROM
    tbl_countries c
    LEFT JOIN tbl_regions r ON c.region = r.id;
GO

-- View untuk menampilkan daftar region
CREATE VIEW vw_region_list AS
SELECT 
    id,
    name
FROM
    tbl_regions;
GO

-- View untuk menampilkan daftar peran
CREATE VIEW vw_role_list AS
SELECT 
    id,
    name
FROM
    tbl_roles;
GO

-- View untuk menampilkan daftar izin
CREATE VIEW vw_permission_list AS
SELECT 
    p.id,
    p.name,
    r.name AS role_permission
FROM
    tbl_permissions p
LEFT JOIN tbl_role_permissions rp ON p.id = rp.permission
LEFT JOIN tbl_roles r ON rp.role = r.id;
GO

-- View untuk menampilkan daftar akun dan perannya
CREATE VIEW vw_account_roles AS
SELECT 
    ar.id,
    a.username,
    r.name AS role_name
FROM
    tbl_account_roles ar
    LEFT JOIN tbl_accounts a ON ar.account = a.id
    LEFT JOIN tbl_roles r ON ar.role = r.id;
GO

-- View untuk menampilkan daftar job histories
CREATE VIEW vw_job_histories AS
SELECT 
    jh.employee,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    jh.start_date,
    jh.end_date,
    jh.status,
    jh.job,
    d.name AS department
FROM
    tbl_job_histories jh
    LEFT JOIN tbl_employees e ON jh.employee = e.id
    LEFT JOIN tbl_departments d ON jh.department = d.id;
GO

-- ========================================
-- FUNCTIONS
-- ========================================

-- Function untuk validasi email
CREATE FUNCTION dbo.IsValidEmail(@Email VARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;
    SET @IsValid = 0;
    
    IF @Email LIKE '_%@__%.__%' AND
       CHARINDEX(' ', @Email) = 0 AND
       LEN(@Email) <= 255
    BEGIN
        SET @IsValid = 1;
    END
    
    RETURN @IsValid;
END;
GO

-- Function untuk validasi nomor telepon
CREATE FUNCTION dbo.IsValidPhoneNumber(@PhoneNumber VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;
    SET @IsValid = 0;
    
    IF @PhoneNumber NOT LIKE '%[^0-9]%' AND LEN(@PhoneNumber) BETWEEN 7 AND 20
    BEGIN
        SET @IsValid = 1;
    END
    
    RETURN @IsValid;
END;
GO

-- Function untuk validasi gender
CREATE FUNCTION dbo.IsValidGender(@Gender VARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;
    SET @IsValid = 0;
    
    IF @Gender IN ('Male', 'Female')
    BEGIN
        SET @IsValid = 1;
    END
    
    RETURN @IsValid;
END;
GO

-- Function untuk validasi password (minimal 8 karakter, huruf besar, huruf kecil, angka, dan simbol)
CREATE FUNCTION dbo.IsValidPassword(@Password VARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;
    SET @IsValid = 0;
    
    IF LEN(@Password) >= 8 AND
       @Password LIKE '%[a-z]%' AND
       @Password LIKE '%[A-Z]%' AND
       @Password LIKE '%[0-9]%' AND
       @Password LIKE '%[^a-zA-Z0-9]%'
    BEGIN
        SET @IsValid = 1;
    END
    
    RETURN @IsValid;
END;
GO

-- Function untuk membandingkan dua password
CREATE FUNCTION dbo.ArePasswordsMatching(@Password1 VARCHAR(255), @Password2 VARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @AreMatching BIT;
    SET @AreMatching = 0;
    
    IF @Password1 = @Password2
    BEGIN
        SET @AreMatching = 1;
    END
    
    RETURN @AreMatching;
END;
GO

-- Function untuk validasi gaji
CREATE FUNCTION dbo.IsValidSalary(@Salary INT)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;
    SET @IsValid = 0;
    
    IF @Salary >= 0 AND @Salary <= 1000000 
    BEGIN
        SET @IsValid = 1;
    END
    
    RETURN @IsValid;
END;
GO

-- ========================================
-- TRIGGERS
-- ========================================

-- Trigger untuk menambahkan riwayat pekerjaan saat karyawan baru ditambahkan
CREATE TRIGGER tr_insert_employee
ON tbl_employees
AFTER INSERT
AS
BEGIN
    INSERT INTO tbl_job_histories (employee, start_date, end_date, status, job, department)
    SELECT 
        inserted.id, 
        GETDATE(),
        NULL, 
        'Active', 
        inserted.job, 
        inserted.department
    FROM inserted;
END;
GO

-- Trigger untuk memperbarui riwayat pekerjaan jika pekerjaan karyawan berubah
CREATE TRIGGER tr_update_employee_job
ON tbl_employees
AFTER UPDATE
AS
BEGIN
    IF UPDATE(job)
    BEGIN
        INSERT INTO tbl_job_histories (employee, start_date, end_date, status, job, department)
        SELECT 
            inserted.id, 
            GETDATE(),
            NULL,
            'Hand Over',
            inserted.job, 
            inserted.department
        FROM inserted;
    END
END;
GO

-- Trigger untuk mencatat riwayat pekerjaan ketika karyawan keluar
CREATE TRIGGER tr_delete_employee
ON tbl_employees
AFTER DELETE
AS
BEGIN
    INSERT INTO tbl_job_histories (employee, start_date, end_date, status, job, department)
    SELECT 
        deleted.id, 
        GETDATE(), 
        GETDATE(), 
        'Resign', 
        deleted.job, 
        deleted.department
    FROM deleted;
END;
GO

-- Sekian hasil query final project kami
-- Terima kasih sudah berkunjung kemari 😊
-- ikan gurame makan cicak, cakeeuupp~~~
-- mana ada ikan gurame makan cicak?

-- That's all for our final project query
-- Thank you for visiting 😊
-- carp eating lizard, greaatt~~~~
-- where is there carp eating lizards?