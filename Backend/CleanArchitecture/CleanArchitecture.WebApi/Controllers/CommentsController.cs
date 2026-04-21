using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Comment;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CommentsController : ControllerBase
    {
        private readonly ICommentRepository _commentRepo;
        private readonly INotificationRepository _notificationRepo;
        private readonly ApplicationDbContext _context;

        public CommentsController(ICommentRepository commentRepo, INotificationRepository notificationRepo, ApplicationDbContext context)
        {
            _commentRepo = commentRepo;
            _notificationRepo = notificationRepo;
            _context = context;
        }

        // GET /api/comments/event/{eventId}
        [HttpGet("event/{eventId:guid}")]
        public async Task<IActionResult> GetByEvent(Guid eventId)
        {
            var comments = await _commentRepo.GetByEventAsync(eventId);
            return Ok(comments);
        }

        // POST /api/comments
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> Add([FromBody] CreateCommentDto dto)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var fullName = $"{User.FindFirstValue(ClaimTypes.GivenName)} {User.FindFirstValue(ClaimTypes.Surname)}".Trim();
            if (string.IsNullOrWhiteSpace(fullName)) fullName = User.FindFirstValue(ClaimTypes.Name) ?? "Kullanici";

            var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var initials = parts.Length >= 2
                ? $"{parts[0][0]}{parts[^1][0]}".ToUpper()
                : fullName.Substring(0, Math.Min(2, fullName.Length)).ToUpper();

            var comment = await _commentRepo.AddAsync(dto, userId, fullName, initials);

            var eventEntity = await _context.Events
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.Id == dto.EventId);

            if (eventEntity != null
                && !string.IsNullOrWhiteSpace(eventEntity.OwnerId)
                && eventEntity.OwnerId != userId)
            {
                await _notificationRepo.CreateAsync(
                    eventEntity.OwnerId,
                    "Yeni Yorum",
                    $"{fullName} kullanicisi {eventEntity.Title} etkinligine yorum yapti.",
                    NotificationType.EventCommented,
                    relatedEventId: eventEntity.Id);
            }

            return Ok(comment);
        }

        // DELETE /api/comments/{id}
        [HttpDelete("{id:guid}")]
        [Authorize]
        public async Task<IActionResult> Delete(Guid id)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            await _commentRepo.DeleteAsync(id, userId);
            return NoContent();
        }
    }
}
