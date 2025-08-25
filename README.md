# HelpDesk Lite 

A self-driven learning project to practice **C#**, **ASP.NET Core MVC**, **SQL Server**, and modern dev workflows (EF Core, Swagger, CI/CD).  
The goal is to showcase skills relevant to software developer roles that value **.NET**, **databases**, and **API design**.

---

## Features (Current Progress)
- ASP.NET Core MVC app with Razor Views (`/Tickets`, `/Agents`)
- SQL Server database (`Tickets`, `Agents` tables + stored procs for Create/Close)
- Entity Framework Core integration
- Swagger API docs at `/swagger`
- GitHub repo with clean structure + safe config (User Secrets for connection strings)

---

## Tech Stack
- C# / .NET 8
- ASP.NET Core MVC + Razor Views
- SQL Server + T-SQL stored procedures
- EF Core + ADO.NET
- Swagger / Swashbuckle
- Git + GitHub

---

## Setup Instructions
### Prerequisites
- [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
- [SQL Server Management Studio (SSMS)](https://aka.ms/ssmsfullsetup)
- [.NET 8 SDK](https://dotnet.microsoft.com/download)

### Steps
1. Clone the repo:
   ```bash
   git clone https://github.com/<your-username>/HelpDeskLite.git
   cd HelpDeskLite