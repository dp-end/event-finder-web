using CleanArchitecture.Core.DTOs.Ticket;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.Application.Entities;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TicketsController : ControllerBase
    {
        private readonly ITicketRepository _ticketRepo;
        private readonly INotificationRepository _notificationRepo;
        private readonly ApplicationDbContext _context;

        public TicketsController(
            ITicketRepository ticketRepo,
            INotificationRepository notificationRepo,
            ApplicationDbContext context)
        {
            _ticketRepo = ticketRepo;
            _notificationRepo = notificationRepo;
            _context = context;
        }

        // GET /api/tickets - oturum acmis kullanicinin biletleri
        [HttpGet]
        public async Task<IActionResult> GetMyTickets()
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var tickets = await _ticketRepo.GetUserTicketsAsync(userId);
            return Ok(tickets);
        }

        // GET /api/tickets/{id}
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var ticket = await _ticketRepo.GetByIdAsync(id, userId);
            if (ticket == null) return NotFound();
            return Ok(ticket);
        }

        // POST /api/tickets/purchase
        [HttpPost("purchase")]
        public async Task<IActionResult> Purchase([FromBody] PurchaseTicketDto dto)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();
            if (User.IsInRole("Club")) return Forbid();

            try
            {
                var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
                if (user == null) return Unauthorized();

                var eventEntity = await _context.Events
                    .Include(e => e.Tickets)
                    .Include(e => e.Club)
                    .FirstOrDefaultAsync(e => e.Id == dto.EventId && e.IsActive);

                if (eventEntity == null)
                    return BadRequest(new { message = "Etkinlik bulunamadi veya aktif degil." });

                if (eventEntity.Tickets.Count >= eventEntity.Quota)
                    return BadRequest(new { message = "Kontenjan doldu." });

                if (eventEntity.Tickets.Any(t => t.ApplicationUserId == userId))
                    return BadRequest(new { message = "Bu etkinlik icin zaten biletiniz var." });

                var ticketNumber = $"TKT-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper()}";
                var ticketEntity = new Ticket
                {
                    Id = Guid.NewGuid(),
                    EventId = dto.EventId,
                    ApplicationUserId = userId,
                    PurchaseDate = DateTime.UtcNow,
                    QrCode = Guid.NewGuid().ToString("N"),
                    TicketNumber = ticketNumber,
                    IsUsed = false
                };

                await using var transaction = await _context.Database.BeginTransactionAsync();
                _context.Tickets.Add(ticketEntity);
                _context.Notifications.Add(new Notification
                {
                    Id = Guid.NewGuid(),
                    ApplicationUserId = userId,
                    Title = "Biletiniz Hazir!",
                    Body = $"'{eventEntity.Title}' etkinligi icin biletiniz basariyla olusturuldu. Bilet No: {ticketNumber}",
                    Type = NotificationType.TicketPurchased,
                    RelatedEventId = eventEntity.Id,
                    RelatedClubId = eventEntity.ClubId,
                    CreatedAt = DateTime.UtcNow,
                    IsRead = false
                });

                var clubOwnerId = eventEntity.Club?.AdminUserId ?? eventEntity.Club?.Id;
                if (!string.IsNullOrWhiteSpace(clubOwnerId)
                    && clubOwnerId != userId)
                {
                    _context.Notifications.Add(new Notification
                    {
                        Id = Guid.NewGuid(),
                        ApplicationUserId = clubOwnerId,
                        Title = "Yeni Bilet Alindi",
                        Body = $"'{eventEntity.Title}' etkinliginiz icin yeni bir bilet alindi. Bilet No: {ticketNumber}",
                        Type = NotificationType.TicketPurchased,
                        RelatedEventId = eventEntity.Id,
                        RelatedClubId = eventEntity.ClubId,
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false
                    });
                }
                else if (!string.IsNullOrWhiteSpace(eventEntity.OwnerId) && eventEntity.OwnerId != userId)
                {
                    _context.Notifications.Add(new Notification
                    {
                        Id = Guid.NewGuid(),
                        ApplicationUserId = eventEntity.OwnerId,
                        Title = "Yeni Bilet Alindi",
                        Body = $"'{eventEntity.Title}' etkinliginiz icin yeni bir bilet alindi. Bilet No: {ticketNumber}",
                        Type = NotificationType.TicketPurchased,
                        RelatedEventId = eventEntity.Id,
                        RelatedClubId = eventEntity.ClubId,
                        CreatedAt = DateTime.UtcNow,
                        IsRead = false
                    });
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                var ticket = await _ticketRepo.GetByIdAsync(ticketEntity.Id, userId);
                var soldCount = await _context.Tickets.CountAsync(t => t.EventId == eventEntity.Id);
                var remainingQuota = eventEntity.Quota - soldCount;
                if (ticket != null) ticket.RemainingQuota = remainingQuota;
                return Ok(ticket);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (DbUpdateException ex)
            {
                return BadRequest(new { message = ex.InnerException?.Message ?? ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // GET /api/tickets/check/{eventId} - kullanici bu etkinlik icin bilet aldi mi?
        [HttpGet("check/{eventId:guid}")]
        public async Task<IActionResult> CheckTicket(Guid eventId)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var hasTicket = await _ticketRepo.HasTicketAsync(eventId, userId);
            var remaining = await _ticketRepo.GetRemainingQuotaAsync(eventId);
            return Ok(new { hasTicket, remainingQuota = remaining });
        }

        // POST /api/tickets/{id}/use - kapi girisi (QR tarama sonrasi)
        [HttpPost("{id:guid}/use")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> MarkAsUsed(Guid id)
        {
            var success = await _ticketRepo.MarkAsUsedAsync(id);
            if (!success) return BadRequest(new { message = "Bilet bulunamadi veya zaten kullanilmis." });
            return Ok(new { message = "Bilet kullanildi olarak isaretlendi." });
        }
    }
}
