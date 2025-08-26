using HelpDeskLite.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class TicketsApiController : ControllerBase
{
    private readonly HelpDeskContext _db;
    public TicketsApiController(HelpDeskContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Tickets.Include(t => t.Agent).ToListAsync());

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var ticket = await _db.Tickets.Include(t => t.Agent).FirstOrDefaultAsync(t => t.Id == id);
        return ticket == null ? NotFound() : Ok(ticket);
    }
}
