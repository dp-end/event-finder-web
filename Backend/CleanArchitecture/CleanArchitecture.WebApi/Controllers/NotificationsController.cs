using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationRepository _notificationRepo;

        public NotificationsController(INotificationRepository notificationRepo)
        {
            _notificationRepo = notificationRepo;
        }

        // GET /api/notifications
        [HttpGet]
        public async Task<IActionResult> GetMyNotifications()
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var notifications = await _notificationRepo.GetUserNotificationsAsync(userId);
            return Ok(notifications);
        }

        // GET /api/notifications/unread-count
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            var count = await _notificationRepo.GetUnreadCountAsync(userId);
            return Ok(new { unreadCount = count });
        }

        // PUT /api/notifications/{id}/read
        [HttpPut("{id:guid}/read")]
        public async Task<IActionResult> MarkAsRead(Guid id)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            await _notificationRepo.MarkAsReadAsync(id, userId);
            return NoContent();
        }

        // PUT /api/notifications/read-all
        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

            await _notificationRepo.MarkAllAsReadAsync(userId);
            return NoContent();
        }
    }
}
