using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Club;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClubsController : ControllerBase
    {
        private readonly IClubRepository _clubRepo;
        private readonly INotificationRepository _notificationRepo;
        private readonly ApplicationDbContext _context;

        public ClubsController(IClubRepository clubRepo, INotificationRepository notificationRepo, ApplicationDbContext context)
        {
            _clubRepo = clubRepo;
            _notificationRepo = notificationRepo;
            _context = context;
        }

        // GET /api/clubs
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var userId = User.FindUserId();
            var result = await _clubRepo.GetAllAsync(userId);
            return Ok(result);
        }

        // GET /api/clubs/popular?count=5
        [HttpGet("popular")]
        public async Task<IActionResult> GetPopular([FromQuery] int count = 5)
        {
            var userId = User.FindUserId();
            var result = await _clubRepo.GetPopularAsync(count, userId);
            return Ok(result);
        }

        // GET /api/clubs/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id)
        {
            var userId = User.FindUserId();
            var result = await _clubRepo.GetByIdAsync(id, userId);
            if (result == null) return NotFound();
            return Ok(result);
        }

        // POST /api/clubs
        [HttpPost]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Create([FromBody] CreateClubDto dto)
        {
            var entity = new Club
            {
                FirstName = dto.Name,
                LastName = "",
                UserName = dto.Name,
                Name = dto.Name,
                Initials = dto.Initials,
                Category = dto.Category,
                Description = dto.Description,
                CoverImageUrl = dto.CoverImageUrl,
                InstagramHandle = dto.InstagramHandle,
                AdminUserId = User.FindUserId()
            };

            var created = await _clubRepo.CreateAsync(entity);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        // PUT /api/clubs/{id}
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> Update(string id, [FromBody] CreateClubDto dto)
        {
            if (!await _clubRepo.ExistsAsync(id)) return NotFound();
            var userId = User.FindUserId();
            var isAdmin = User.IsInRole("Admin") || User.IsInRole("SuperAdmin");
            var ownsClub = await _context.Clubs.AnyAsync(c => c.Id == id && c.AdminUserId == userId);
            if (!isAdmin && !ownsClub) return Forbid();

            var entity = new Club
            {
                Name = dto.Name,
                Initials = dto.Initials,
                Category = dto.Category,
                Description = dto.Description,
                CoverImageUrl = dto.CoverImageUrl,
                InstagramHandle = dto.InstagramHandle
            };

            await _clubRepo.UpdateAsync(id, entity);
            return NoContent();
        }

        // DELETE /api/clubs/{id}
        [HttpDelete("{id}")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public async Task<IActionResult> Delete(string id)
        {
            if (!await _clubRepo.ExistsAsync(id)) return NotFound();
            await _clubRepo.DeleteAsync(id);
            return NoContent();
        }

        // POST /api/clubs/{id}/follow  — takip et / bırak (toggle)
        [HttpPost("{id}/follow")]
        [Authorize]
        public async Task<IActionResult> Follow(string id)
        {
            var userId = User.FindUserId();
            if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();
            if (!await _clubRepo.ExistsAsync(id)) return NotFound();

            bool following = await _clubRepo.FollowAsync(id, userId);
            if (following)
            {
                var club = await _context.Clubs.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
                if (club != null && !string.IsNullOrWhiteSpace(club.Id) && club.Id != userId)
                {
                    await _notificationRepo.CreateAsync(
                        club.Id,
                        "Yeni Takipci",
                        $"{BuildActorName()} kullanicisi {club.Name} kulubunu takip etti.",
                        NotificationType.ClubFollowed,
                        relatedClubId: club.Id);
                }
            }

            var followerCount = await _context.ClubFollowers.CountAsync(f => f.ClubId == id);
            var followingClubCount = await _context.ClubFollowers.CountAsync(f => f.ApplicationUserId == userId);
            return Ok(new
            {
                following,
                followerCount,
                followingClubCount,
                message = following ? "Kulup takip edildi." : "Takip birakildi."
            });
        }

        private string BuildActorName()
        {
            var givenName = User.FindFirst(System.Security.Claims.ClaimTypes.GivenName)?.Value;
            var surname = User.FindFirst(System.Security.Claims.ClaimTypes.Surname)?.Value;
            var fullName = $"{givenName} {surname}".Trim();
            if (!string.IsNullOrWhiteSpace(fullName)) return fullName;

            return User.Identity?.Name
                ?? User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value
                ?? "Bir kullanici";
        }
    }
}
