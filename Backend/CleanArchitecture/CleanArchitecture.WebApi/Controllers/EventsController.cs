using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Event;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.IO;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EventsController : ControllerBase
    {
        private readonly IEventRepository _eventRepo;
        private readonly INotificationRepository _notificationRepo;
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public EventsController(
            IEventRepository eventRepo,
            INotificationRepository notificationRepo,
            ApplicationDbContext context,
            IWebHostEnvironment environment)
        {
            _eventRepo = eventRepo;
            _notificationRepo = notificationRepo;
            _context = context;
            _environment = environment;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] string query = null,
            [FromQuery] string category = null,
            [FromQuery] bool? freeOnly = null,
            [FromQuery] decimal? maxPrice = null,
            [FromQuery] string timePeriod = null,
            [FromQuery] string eventType = null,
            [FromQuery] string creatorType = null)
        {
            var userId = User.FindUserId();
            var resolvedCreatorType = string.IsNullOrWhiteSpace(eventType) ? creatorType : eventType;

            if (string.IsNullOrWhiteSpace(query) && string.IsNullOrWhiteSpace(category) &&
                freeOnly == null && maxPrice == null && string.IsNullOrWhiteSpace(timePeriod) &&
                string.IsNullOrWhiteSpace(resolvedCreatorType))
            {
                var all = await _eventRepo.GetAllAsync(userId, resolvedCreatorType);
                return Ok(all);
            }

            var result = await _eventRepo.SearchAsync(query, category, freeOnly, maxPrice, timePeriod, userId, resolvedCreatorType);
            return Ok(result);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            var userId = User.FindUserId();
            var result = await _eventRepo.GetByIdAsync(id, userId);
            if (result == null) return NotFound();
            return Ok(result);
        }

        [HttpGet("club/{clubId}")]
        public async Task<IActionResult> GetByClub(string clubId)
        {
            var userId = User.FindUserId();
            var result = await _eventRepo.GetByClubAsync(clubId, userId);
            return Ok(result);
        }

        [HttpGet("owner/{ownerId}")]
        public async Task<IActionResult> GetByOwner(string ownerId)
        {
            if (string.IsNullOrWhiteSpace(ownerId)) return BadRequest(new { message = "Kullanici id bos olamaz." });

            var currentUserId = User.FindUserId();
            var result = await _eventRepo.GetByOwnerAsync(ownerId, currentUserId);
            return Ok(result);
        }

        [HttpGet("attendee/{userId}")]
        public async Task<IActionResult> GetAttendedByUser(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return BadRequest(new { message = "Kullanici id bos olamaz." });

            var currentUserId = User.FindUserId();
            var result = await _eventRepo.GetAttendedByUserAsync(userId, currentUserId);
            return Ok(result);
        }

        [HttpGet("mine")]
        [Authorize]
        public async Task<IActionResult> GetMine()
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var result = await _eventRepo.GetByOwnerAsync(userId, userId);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = "Basic,Club,Admin,SuperAdmin")]
        public async Task<IActionResult> Create([FromBody] CreateEventDto dto)
        {
            var ownerId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(ownerId)) return Unauthorized();

            var resolvedClubId = dto.ClubId;
            if (resolvedClubId == null && ownerId != null)
            {
                var adminClub = _context.Clubs.FirstOrDefault(c => c.Id == ownerId || c.AdminUserId == ownerId);
                resolvedClubId = adminClub?.Id;
            }

            var ownedClub = _context.Clubs.FirstOrDefault(c => c.Id == ownerId || c.AdminUserId == ownerId);
            var isAdmin = User.IsInRole("Admin") || User.IsInRole("SuperAdmin");
            if (ownedClub != null)
            {
                resolvedClubId = ownedClub.Id;
            }
            else if (!isAdmin)
            {
                resolvedClubId = null;
            }

            var entity = new Event
            {
                Title = dto.Title,
                Description = dto.Description,
                Date = dto.Date,
                Location = dto.Location,
                Address = dto.Address,
                Price = dto.Price,
                Quota = dto.Quota,
                ImageUrl = dto.ImageUrl,
                CategoryId = dto.CategoryId,
                ClubId = resolvedClubId,
                OwnerId = ownerId,
                IsActive = true
            };

            var created = await _eventRepo.CreateAsync(entity);
            var response = await _eventRepo.GetByIdAsync(created.Id, ownerId);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, response);
        }

        [HttpPost("upload-image")]
        [Authorize(Roles = "Basic,Club,Admin,SuperAdmin")]
        public async Task<IActionResult> UploadImage([FromForm] IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Dosya secilmedi." });

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            if (!allowed.Contains(extension))
                return BadRequest(new { message = "Sadece jpg, jpeg, png veya webp yuklenebilir." });

            var root = _environment.WebRootPath;
            if (string.IsNullOrWhiteSpace(root))
            {
                root = Path.Combine(_environment.ContentRootPath, "wwwroot");
            }

            var uploadDir = Path.Combine(root, "images", "events");
            Directory.CreateDirectory(uploadDir);

            var fileName = $"{Guid.NewGuid():N}{extension}";
            var fullPath = Path.Combine(uploadDir, fileName);

            await using (var stream = System.IO.File.Create(fullPath))
            {
                await file.CopyToAsync(stream);
            }

            var publicPath = $"/images/events/{fileName}";
            return Ok(new { imageUrl = publicPath });
        }

        [HttpPut("{id:guid}")]
        [Authorize]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateEventDto dto)
        {
            if (!await _eventRepo.ExistsAsync(id)) return NotFound();
            var existing = await _context.Events.FindAsync(id);
            var userId = User.FindUserId();
            var isAdmin = User.IsInRole("Admin") || User.IsInRole("SuperAdmin");
            if (existing == null) return NotFound();
            if (!isAdmin && existing.OwnerId != userId) return Forbid();

            var soldCount = _context.Tickets.Count(t => t.EventId == id);
            if (dto.Quota < soldCount)
            {
                return BadRequest(new { message = $"Kontenjan alinmis bilet sayisindan az olamaz. Mevcut bilet: {soldCount}." });
            }

            var entity = new Event
            {
                Title = dto.Title,
                Description = dto.Description,
                Date = dto.Date,
                Location = dto.Location,
                Address = dto.Address,
                Price = dto.Price,
                Quota = dto.Quota,
                ImageUrl = dto.ImageUrl,
                CategoryId = dto.CategoryId,
                IsActive = dto.IsActive
            };

            await _eventRepo.UpdateAsync(id, entity);
            return NoContent();
        }

        [HttpDelete("{id:guid}")]
        [Authorize]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!await _eventRepo.ExistsAsync(id)) return NotFound();

            var userId = User.FindUserId();
            var isAdmin = User.IsInRole("Admin") || User.IsInRole("SuperAdmin");

            if (!isAdmin)
            {
                var existing = await _context.Events.FindAsync(id);
                if (existing == null) return NotFound();
                if (existing.OwnerId != userId) return Forbid();
            }

            await _eventRepo.DeleteAsync(id);
            return NoContent();
        }

        [HttpPost("{id:guid}/like")]
        [Authorize]
        public async Task<IActionResult> Like(Guid id)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();
            if (!await _eventRepo.ExistsAsync(id)) return NotFound();

            bool liked = await _eventRepo.LikeAsync(id, userId);
            if (liked)
            {
                var eventEntity = await _context.Events
                    .AsNoTracking()
                    .FirstOrDefaultAsync(e => e.Id == id);

                if (eventEntity != null
                    && !string.IsNullOrWhiteSpace(eventEntity.OwnerId)
                    && eventEntity.OwnerId != userId)
                {
                    await _notificationRepo.CreateAsync(
                        eventEntity.OwnerId,
                        "Yeni Begeni",
                        $"{BuildActorName()} kullanicisi {eventEntity.Title} etkinligini begendi.",
                        NotificationType.EventLiked,
                        relatedEventId: eventEntity.Id);
                }
            }

            return Ok(new { liked, message = liked ? "Favorilere eklendi." : "Favorilerden cikarildi." });
        }

        private string BuildActorName()
        {
            var givenName = User.FindFirst(ClaimTypes.GivenName)?.Value;
            var surname = User.FindFirst(ClaimTypes.Surname)?.Value;
            var fullName = $"{givenName} {surname}".Trim();
            if (!string.IsNullOrWhiteSpace(fullName)) return fullName;

            return User.Identity?.Name
                ?? User.FindFirst(ClaimTypes.Name)?.Value
                ?? "Bir kullanici";
        }
    }
}
