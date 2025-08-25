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
    public async Task<IActionResult> Get() =>
        Ok(await _db.Tickets.Include(t => t.Agent).ToListAsync());
}
