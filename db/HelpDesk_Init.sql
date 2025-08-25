/* ========= 1) Create DB if not exists ========= */
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'HelpDeskLite')
BEGIN
    PRINT('Creating database HelpDeskLite...');
    CREATE DATABASE HelpDeskLite;
END
GO

USE HelpDeskLite;
GO

/* ========= 2) Create tables (idempotent) ========= */

/* Agents */
IF OBJECT_ID(N'dbo.Agents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Agents
    (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        [Name]      NVARCHAR(100)  NOT NULL,
        Email       NVARCHAR(255)  NOT NULL UNIQUE,
        IsActive    BIT            NOT NULL CONSTRAINT DF_Agents_IsActive DEFAULT(1),
        CreatedAt   DATETIME2(0)   NOT NULL CONSTRAINT DF_Agents_CreatedAt DEFAULT(SYSDATETIME())
    );
END
GO

/* Tickets */
IF OBJECT_ID(N'dbo.Tickets', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Tickets
    (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        Title       NVARCHAR(200)  NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [Status]    VARCHAR(20)    NOT NULL CONSTRAINT DF_Tickets_Status DEFAULT('Open'),
        Priority    VARCHAR(10)    NOT NULL CONSTRAINT DF_Tickets_Priority DEFAULT('Normal'),
        AgentId     INT            NULL,
        CreatedAt   DATETIME2(0)   NOT NULL CONSTRAINT DF_Tickets_CreatedAt DEFAULT(SYSDATETIME()),
        ClosedAt    DATETIME2(0)   NULL,
        CONSTRAINT CK_Tickets_Status   CHECK ([Status] IN ('Open','InProgress','Closed')),
        CONSTRAINT CK_Tickets_Priority CHECK (Priority IN ('Low','Normal','High','Urgent')),
        CONSTRAINT FK_Tickets_Agents   FOREIGN KEY (AgentId) REFERENCES dbo.Agents(Id) ON DELETE SET NULL
    );

    /* Helpful indexes */
    CREATE INDEX IX_Tickets_Agent_Status ON dbo.Tickets(AgentId, [Status]);
    CREATE INDEX IX_Tickets_CreatedAt    ON dbo.Tickets(CreatedAt DESC);
END
GO

/* ========= 3) Stored procedures (create or alter) ========= */

/* CreateTicket: inserts and returns new Ticket Id */
IF OBJECT_ID(N'dbo.CreateTicket', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.CreateTicket AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.CreateTicket
    @Title       NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @Priority    VARCHAR(10)   = 'Normal',
    @AgentId     INT           = NULL,
    @NewTicketId INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Priority NOT IN ('Low','Normal','High','Urgent')
        THROW 50001, 'Invalid priority.', 1;

    IF @AgentId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Agents WHERE Id=@AgentId AND IsActive=1)
        THROW 50002, 'Agent not found or inactive.', 1;

    INSERT INTO dbo.Tickets (Title, [Description], Priority, AgentId)
    VALUES (@Title, @Description, @Priority, @AgentId);

    SET @NewTicketId = SCOPE_IDENTITY();
END
GO

/* CloseTicket: marks ticket Closed and stamps ClosedAt */
IF OBJECT_ID(N'dbo.CloseTicket', N'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.CloseTicket AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.CloseTicket
    @TicketId           INT,
    @ClosedByAgentId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Tickets WHERE Id=@TicketId)
        THROW 50003, 'Ticket not found.', 1;

    /* Optional: ensure the closing agent exists if provided */
    IF @ClosedByAgentId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Agents WHERE Id=@ClosedByAgentId AND IsActive=1)
        THROW 50004, 'Closing agent not found or inactive.', 1;

    /* Prevent re-closing */
    IF EXISTS (SELECT 1 FROM dbo.Tickets WHERE Id=@TicketId AND [Status]='Closed')
        THROW 50005, 'Ticket already closed.', 1;

    UPDATE dbo.Tickets
       SET [Status]  = 'Closed',
           ClosedAt  = SYSDATETIME(),
           /* If a closer is provided and no agent was set, attach it */
           AgentId   = COALESCE(AgentId, @ClosedByAgentId)
     WHERE Id = @TicketId;
END
GO

/* ========= 4) Seed data (safe to skip if exists) ========= */
IF NOT EXISTS (SELECT 1 FROM dbo.Agents)
BEGIN
    INSERT INTO dbo.Agents ([Name], Email) VALUES
    (N'Alex Agent',  N'alex.agent@example.com'),
    (N'Jamie Jones', N'jamie.jones@example.com');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Tickets)
BEGIN
    INSERT INTO dbo.Tickets (Title, [Description], Priority, AgentId)
    VALUES
    (N'Can’t log in', N'User reports invalid credentials error.', 'High', 1),
    (N'Feature request', N'Add dark mode to portal.', 'Normal', NULL);
END
GO

/* ========= 5) Quick smoke tests ========= */
DECLARE @newId INT;
EXEC dbo.CreateTicket
    @Title = N'Test ticket via SP',
    @Description = N'Created by CreateTicket proc',
    @Priority = 'Urgent',
    @AgentId = 2,
    @NewTicketId = @newId OUTPUT;

PRINT CONCAT('Created Ticket Id = ', @newId);

-- Close the seeded "Feature request" ticket if still open
IF EXISTS (SELECT 1 FROM dbo.Tickets WHERE Title=N'Feature request' AND [Status] <> 'Closed')
BEGIN
    DECLARE @closeId INT = (SELECT TOP(1) Id FROM dbo.Tickets WHERE Title=N'Feature request');
    EXEC dbo.CloseTicket @TicketId=@closeId, @ClosedByAgentId=1;
    PRINT CONCAT('Closed Ticket Id = ', @closeId);
END
GO

