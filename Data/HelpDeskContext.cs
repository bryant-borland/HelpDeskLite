using Microsoft.EntityFrameworkCore;
using HelpDeskLite.Models;

namespace HelpDeskLite.Data
{
    public class HelpDeskContext : DbContext
    {
        public HelpDeskContext(DbContextOptions<HelpDeskContext> options) : base(options) { }

        public DbSet<Ticket> Tickets { get; set; }
        public DbSet<Agent> Agents { get; set; }
    }
}