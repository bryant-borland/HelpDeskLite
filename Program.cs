using HelpDeskLite.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<HelpDeskContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("HelpDesk")));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();

app.MapGet("/health/db", async (HelpDeskContext db) =>
{
    try
    {
        var canConnect = await db.Database.CanConnectAsync();
        var ticketCount = await db.Tickets.CountAsync();
        var agentCount = await db.Agents.CountAsync();

        return Results.Ok(new
        {
            canConnect,
            ticketCount,
            agentCount
        });
    }
    catch (Exception ex)
    {
        return Results.Problem(title: "DB check failed", detail: ex.Message);
    }
});

app.Run();
