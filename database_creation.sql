--**********************************************************************************************--
-- Title: Example Database Creation
-- Author: Brian Jhong
-- Desc: This file demonstrates how to design and create; 
--       tables, constraints, views, stored procedures, and permissions
-- Change Log: When,Who,What
-- 2018-11-13,Brian Jhong,Created File
-- 2018-11-13,Brian Jhong,Created Students, Courses, Enrollments Tables With Constraints
-- 2018-11-13,Brian Jhong,Created UDF fGetCourseStartDate  
-- 2018-11-14,Brian Jhong,Created Basic Views
-- 2018-11-15,Brian Jhong,Created Reporting View
-- 2018-11-17,Brian Jhong,Created Students, Courses, Enrollments Stored Procedures
-- 2018-11-18,Brian Jhong,Created Students, Courses, Enrollments Stored Procedures Test Code 
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'DB_BrianJhong')
	 Begin 
	  Alter Database [DB_BrianJhong] set Single_user With Rollback Immediate;
	  Drop Database DB_BrianJhong;
	 End
	Create Database DB_BrianJhong;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use DB_BrianJhong;

-- Create Tables -- 
-- Add Constraints --

Create Table Students (
	StudentID int not null primary key identity(1,1),
	StudentNumber nvarchar(100) not null unique, 
	StudentFirstName nvarchar(100) not null,
	StudentLastName nvarchar(100) not null, 
	StudentEmail nvarchar(100) not null unique, 
	StudentPhone nvarchar(100) null check(StudentPhone like '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'), 
	StudentAddress1 nvarchar(100) not null, 
	StudentAddress2 nvarchar(100) null,
	StudentCity nvarchar(100) not null,  
	StudentStateCode nvarchar(100) not null,  
	StudentZipCode nvarchar(100) not null check(StudentZipCode like '[0-9][0-9][0-9][0-9][0-9]' or 
												StudentZipCode like '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
);
go

Create Table Courses (
	CourseID int not null primary key identity(1,1),
	CourseName nvarchar(100) not null unique, 
	CourseStartDate date null,
	CourseEndDate date null,
	CourseStartTime time null,
	CourseEndTime time null,
	CourseWeekDays nvarchar(100) null,
	CourseCurrentPrice money null, 
	Constraint DateValid check (CourseEndDate > CourseStartDate),
	Constraint TimeValid check (CourseEndTime > CourseStartTime)
);
go

Create Table Enrollments (
	EnrollmentID int not null primary key identity(1,1),
	StudentID int not null foreign key references Students(StudentID),
	CourseID int not null foreign key references Courses(CourseID),
	EnrollmentDateTime datetime not null default getdate(),
	EnrollmentPrice money not null
);
go

Create Function dbo.fGetCourseStartDate(@CourseID int)
	Returns date
	As 
		Begin
			Return(
				Select c.CourseStartDate 
				From Courses As c
				Where @CourseID = c.CourseID
			);
	End
go 

Alter Table Enrollments Add Constraint chEnrollmentDate
	check(convert(date, EnrollmentDateTime) < dbo.fgetCourseStartDate(CourseID))
go

-- Add Views -- 
Create View vStudents As
	Select 
		StudentID,
		StudentNumber, 
		StudentFirstName,
		StudentLastName, 
		StudentEmail, 
		StudentPhone, 
		StudentAddress1, 
		StudentAddress2,
		StudentCity,  
		StudentStateCode,  
		StudentZipCode
	From Students;
go

Create View vCourses As
	Select 
		CourseID,
		CourseName, 
		CourseStartDate,
		CourseEndDate,
		CourseStartTime,
		CourseEndTime,
		CourseWeekDays,
		CourseCurrentPrice
	From Courses;
go

Create View vEnrollments As
	Select 
		EnrollmentID,
		StudentID,
		CourseID,
		EnrollmentDateTime,
		EnrollmentPrice
	From Enrollments;
go

Create View vReport As
	Select 
		s.StudentID,
		s.StudentNumber, 
		s.StudentFirstName,
		s.StudentLastName, 
		s.StudentEmail, 
		s.StudentPhone, 
		s.StudentAddress1, 
		s.StudentAddress2,
		s.StudentCity,  
		s.StudentStateCode,  
		s.StudentZipCode, 
		e.EnrollmentID,
		e.EnrollmentDateTime,
		e.EnrollmentPrice,
		c.CourseID,
		c.CourseName, 
		c.CourseStartDate,
		c.CourseEndDate,
		c.CourseStartTime,
		c.CourseEndTime,
		c.CourseWeekDays,
		c.CourseCurrentPrice
	From Students As s
	Inner Join Enrollments As e 
	On e.StudentID = s.StudentID
	Inner Join Courses As c 
	On c.CourseID = e.CourseID
go 

-- Add Stored Procedures --

----- STUDENTS PROCEDURES START HERE -----

Create Procedure pInsStudents
(	@StudentNumber nvarchar(100),
	@StudentFirstName nvarchar(100),
	@StudentLastName nvarchar(100), 
	@StudentEmail nvarchar(100),  
	@StudentPhone nvarchar(100), 
	@StudentAddress1 nvarchar(100), 
	@StudentAddress2 nvarchar(100), 
	@StudentCity nvarchar(100), 
	@StudentStateCode nvarchar(100), 
	@StudentZipCode nvarchar(100)
)
/* Author: Brian Jhong 
** Desc: Processes Insertion of data into the Students table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pInsCourses stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Insert Into 
		Students(
			StudentNumber, 
			StudentFirstName,
			StudentLastName, 
			StudentEmail, 
			StudentPhone, 
			StudentAddress1, 
			StudentAddress2,
			StudentCity,  
			StudentStateCode,  
			StudentZipCode
		) 
	Values (
		@StudentNumber, 
		@StudentFirstName,
		@StudentLastName, 
		@StudentEmail, 
		@StudentPhone, 
		@StudentAddress1, 
		@StudentAddress2,
		@StudentCity,  
		@StudentStateCode,  
		@StudentZipCode
	);
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pUpdStudents
(	@StudentID int,
	@StudentNumber nvarchar(100),
	@StudentFirstName nvarchar(100),
	@StudentLastName nvarchar(100), 
	@StudentEmail nvarchar(100),  
	@StudentPhone nvarchar(100), 
	@StudentAddress1 nvarchar(100), 
	@StudentAddress2 nvarchar(100), 
	@StudentCity nvarchar(100), 
	@StudentStateCode nvarchar(100), 
	@StudentZipCode nvarchar(100)
)
/* Author: Brian Jhong 
** Desc: Processes Updating of data in the Students table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pUpdStudents stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	UPDATE Students
    Set StudentNumber = @StudentNumber,
		StudentFirstName = @StudentFirstName,
		StudentLastName = @StudentLastName,
		StudentEmail = @StudentEmail,
		StudentPhone = @StudentPhone,
		StudentAddress1 = @StudentAddress1,
		StudentAddress2 = @StudentAddress2,
		StudentCity = @StudentCity,
		StudentStateCode = @StudentStateCode,
		StudentZipCode = @StudentZipCode
    Where StudentID = @StudentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pDelStudents
(	@StudentID int
)
/* Author: Brian Jhong 
** Desc: Processes Deletion of data in the Students table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pDelStudents stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Delete 
	 From Students 
	  Where StudentID = @StudentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

----- Enrollments PROCEDURES START HERE -----

Create Procedure pInsEnrollments
(	@StudentID int,
	@CourseID int,
	@EnrollmentDateTime datetime,
	@EnrollmentPrice money
)
/* Author: Brian Jhong 
** Desc: Processes Insertion of data into the Enrollments table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pInsEnrollments stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Insert Into 
		Enrollments(
			StudentID,
			CourseID,
			EnrollmentDateTime,
			EnrollmentPrice
		) 
	Values (
		@StudentID,
		@CourseID,
		@EnrollmentDateTime,
		@EnrollmentPrice
	);
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pUpdEnrollments
(	@EnrollmentID int,
	@StudentID int,
	@CourseID int,
	@EnrollmentDateTime datetime,
	@EnrollmentPrice money
)
/* Author: Brian Jhong 
** Desc: Processes Updating of data in the Enrollments table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pUpdEnrollments stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	UPDATE Enrollments
    Set StudentID = @StudentID,
		CourseID = @CourseID,
		EnrollmentDateTime = @EnrollmentDateTime,
		EnrollmentPrice = @EnrollmentPrice
    Where EnrollmentID = @EnrollmentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pDelEnrollments
(	@EnrollmentID int
)
/* Author: Brian Jhong 
** Desc: Processes Deletion of data in the Enrollments table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pDelEnrollments stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Delete 
	 From Enrollments 
	  Where EnrollmentID = @EnrollmentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

----- COURSES PROCEDURES START HERE -----

Create Procedure pInsCourses
(	@CourseName nvarchar(100), 
	@CourseStartDate date,
	@CourseEndDate date,
	@CourseStartTime time,
	@CourseEndTime time,
	@CourseWeekDays nvarchar(100),
	@CourseCurrentPrice money 
)
/* Author: Brian Jhong 
** Desc: Processes Insertion of data into the Courses table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pInsCourses stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Insert Into 
		Courses(
			CourseName, 
			CourseStartDate,
			CourseEndDate,
			CourseStartTime,
			CourseEndTime,
			CourseWeekDays,
			CourseCurrentPrice
		) 
	Values (
		@CourseName, 
		@CourseStartDate,
		@CourseEndDate,
		@CourseStartTime,
		@CourseEndTime,
		@CourseWeekDays,
		@CourseCurrentPrice
	);
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pUpdCourses
(	@CourseID int,
	@CourseName nvarchar(100), 
	@CourseStartDate date,
	@CourseEndDate date,
	@CourseStartTime time,
	@CourseEndTime time,
	@CourseWeekDays nvarchar(100),
	@CourseCurrentPrice money 
)
/* Author: Brian Jhong 
** Desc: Processes Updating of data in the Courses table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pUpdCourses stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	UPDATE Courses
    Set CourseName = @CourseName,
		CourseStartDate = @CourseStartDate,
		CourseEndDate = @CourseEndDate,
		CourseStartTime = @CourseStartTime,
		CourseEndTime = @CourseEndTime,
		CourseWeekDays = @CourseWeekDays,
		CourseCurrentPrice = @CourseCurrentPrice
    Where CourseID = @CourseID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pDelCourses
(	@CourseID int
)
/* Author: Brian Jhong 
** Desc: Processes Deletion of data in the Courses table. 
** Change Log: When,Who,What
** 2018-11-17,Brian Jhong,Created pDelCourses stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
	Delete 
	 From Courses 
	  Where CourseID = @CourseID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- Set Permissions --

----- DENY OBJECT PERMISSIONS START HERE -----
Deny Select, Insert, Update, Delete On Students To Public; 
Deny Select, Insert, Update, Delete On Enrollments To Public; 
Deny Select, Insert, Update, Delete On Courses To Public; 

----- PERMISSIONS FOR VIEWS START HERE -----
Grant Select On vStudents To Public;
Grant Select On vEnrollments To Public;
Grant Select On vCourses To Public;

----- PERMISSIONS FOR STUDENT PROCEDURES START HERE -----
Grant Execute On pInsStudents To Public;
Grant Execute On pUpdStudents To Public;
Grant Execute On pDelStudents To Public;

----- PERMISSIONS FOR ENROLLMENTS PROCEDURES START HERE -----
Grant Execute On pInsEnrollments To Public;
Grant Execute On pUpdEnrollments To Public;
Grant Execute On pDelEnrollments To Public;

----- PERMISSIONS FOR COURSES PROCEDURES START HERE -----
Grant Execute On pInsCourses To Public;
Grant Execute On pUpdCourses To Public;
Grant Execute On pDelCourses To Public;


--< Test Views and Sprocs >-- 

-- Testing Views
Select * From vStudents;
go

Select * From vCourses;
go

Select * From vEnrollments;
go

Select * From vReport; 
go

-- Testing Sprocs

----- STUDENT PROCEDURES TEST CODE START HERE -----

Declare @Status int;
Exec @Status = pInsStudents 
				@StudentNumber = 'B-Smith-071',
				@StudentFirstName = 'Bob',
				@StudentLastName = 'Smith',
				@StudentEmail = 'Bsmith@HipMail.com',
				@StudentPhone = '206-111-2222',
				@StudentAddress1 = '123 Main St.',
				@StudentAddress2 = '124 Main St.',
				@StudentCity = 'Seattle',
				@StudentStateCode = 'WA',
				@StudentZipCode = '98001-1234'
Select Case @Status
  When +1 Then 'Insert was successful!'
  When -1 Then 'Insert failed! Common Issues: Duplicate Data'
  End as [Status]
go

Declare @Status int;
Exec @Status = pInsStudents 
				@StudentNumber = 'W-Smith-222',
				@StudentFirstName = 'Will',
				@StudentLastName = 'Smith',
				@StudentEmail = 'Wsmith@HipMail.com',
				@StudentPhone = '255-555-5555',
				@StudentAddress1 = '321 York St.',
				@StudentAddress2 = '124 York St.',
				@StudentCity = 'Seattle',
				@StudentStateCode = 'WA',
				@StudentZipCode = '98333'
Select Case @Status
  When +1 Then 'Insert was successful!'
  When -1 Then 'Insert failed! Common Issues: Duplicate Data'
  End as [Status]
go


Declare @Status int;
Exec @Status = pUpdStudents
				@StudentID = @@IDENTITY, 
				@StudentNumber = 'B-Jhong-198',
				@StudentFirstName = 'Brian',
				@StudentLastName = 'Jhong',
				@StudentEmail = 'jhongb@HipMail.com',
				@StudentPhone = '425-222-3333',
				@StudentAddress1 = '1234 Brooklyn Ave.',
				@StudentAddress2 = '1235 Brooklyn Ave.',
				@StudentCity = 'Lynnwood',
				@StudentStateCode = 'WA',
				@StudentZipCode = '98067';
Select Case @Status
  When +1 Then 'Update was successful!'
  When -1 Then 'Update failed! Common Issues: Duplicate Data or Foreign Key Violation'
  End as [Status]
go

Declare @Status int;
Exec @Status = pDelStudents @StudentID = @@IDENTITY;
Select Case @Status
  When +1 Then 'Delete was successful!'
  When -1 Then 'Delete failed! Common Issues: Foreign Key Violation'
  End as [Status]
go

----- COURSES PROCEDURES TEST CODE START HERE -----

Declare @Status int;
Exec @Status = pInsCourses 
				@CourseName = 'SQL1 - Winter 2017', 
				@CourseStartDate = '1/10/2017',
				@CourseEndDate = '1/24/2017',
				@CourseStartTime = '6:00:00 PM',
				@CourseEndTime = '8:50:00 PM',
				@CourseWeekDays = 'T-Th',
				@CourseCurrentPrice = '399'
Select Case @Status
  When +1 Then 'Insert was successful!'
  When -1 Then 'Insert failed! Common Issues: Duplicate Data'
  End as [Status]
go

Declare @Status int;
Exec @Status = pInsCourses 
				@CourseName = 'SQL2 - Winter 2017', 
				@CourseStartDate = '1/2/2017',
				@CourseEndDate = '1/10/2017',
				@CourseStartTime = '1:00:00 PM',
				@CourseEndTime = '2:50:00 PM',
				@CourseWeekDays = 'W-F',
				@CourseCurrentPrice = '499'
Select Case @Status
  When +1 Then 'Insert was successful!'
  When -1 Then 'Insert failed! Common Issues: Duplicate Data'
  End as [Status]
go
				
Declare @Status int;
Exec @Status = pUpdCourses
				@CourseID = @@IDENTITY, 
				@CourseName = 'SQL3 - Winter 2017', 
				@CourseStartDate = '1/3/2017',
				@CourseEndDate = '1/21/2017',
				@CourseStartTime = '9:00:00 AM',
				@CourseEndTime = '10:30:00 AM',
				@CourseWeekDays = 'M-W',
				@CourseCurrentPrice = '299'
Select Case @Status
  When +1 Then 'Update was successful!'
  When -1 Then 'Update failed! Common Issues: Duplicate Data or Foreign Key Violation'
  End as [Status]
go

Declare @Status int;
Exec @Status = pDelCourses @CourseID = @@IDENTITY;
Select Case @Status
  When +1 Then 'Delete was successful!'
  When -1 Then 'Delete failed! Common Issues: Foreign Key Violation'
  End as [Status]
go

----- ENROLLMENT PROCEDURES TEST CODE START HERE -----

Declare @Status int;
Exec @Status = pInsEnrollments 
				@StudentID = 1,
				@CourseID = 1,
				@EnrollmentDateTime = '1/3/2017',
				@EnrollmentPrice = '399'
Select Case @Status
  When +1 Then 'Insert was successful!'
  When -1 Then 'Insert failed! Common Issues: Duplicate Data'
  End as [Status]
go

/* Extra Insert Test
Declare @Status int;
Exec @Status = pInsEnrollments 
				@StudentID = 2,
				@CourseID = 2,
				@EnrollmentDateTime = '1/4/2017',
				@EnrollmentPrice = '199'
Select Case @Status
  When +1 Then 'Insert was successful!'
  When -1 Then 'Insert failed! Common Issues: Duplicate Data'
  End as [Status]
go
*/		
			
Declare @Status int;
Exec @Status = pUpdEnrollments
				@EnrollmentID = @@IDENTITY,
				@StudentID = 1,
				@CourseID = 1,
				@EnrollmentDateTime = '1/5/2017',
				@EnrollmentPrice = '1999'
Select Case @Status
  When +1 Then 'Update was successful!'
  When -1 Then 'Update failed! Common Issues: Duplicate Data or Foreign Key Violation'
  End as [Status]
go

Declare @Status int;
Exec @Status = pDelEnrollments @EnrollmentID = @@IDENTITY;
Select Case @Status
  When +1 Then 'Delete was successful!'
  When -1 Then 'Delete failed! Common Issues: Foreign Key Violation'
  End as [Status]
go

/**************************************************************************************************/