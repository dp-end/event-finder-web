using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Event;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CleanArchitecture.Infrastructure.Repositories
{
    public class EventRepository : IEventRepository
    {
        private readonly ApplicationDbContext _context;

        public EventRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<EventListDto>> GetAllAsync(string currentUserId = null, string creatorType = null)
        {
            var query = ApplyCreatorTypeFilter(BaseListQuery(), creatorType).OrderBy(e => e.Date);
            return await MapToListDto(query, currentUserId);
        }

        public async Task<IEnumerable<EventListDto>> SearchAsync(
            string query, string categoryName, bool? freeOnly, decimal? maxPrice, string timePeriod, string currentUserId = null, string creatorType = null)
        {
            var now = DateTime.UtcNow;
            var dbQuery = ApplyCreatorTypeFilter(BaseListQuery(), creatorType);

            if (!string.IsNullOrWhiteSpace(query))
            {
                dbQuery = dbQuery.Where(e =>
                    e.Title.Contains(query)
                    || e.Description.Contains(query)
                    || (e.Club != null && e.Club.Name.Contains(query)));
            }

            if (!string.IsNullOrWhiteSpace(categoryName) && categoryName != "Tümü" && categoryName != "Tumu" && categoryName != "All")
                dbQuery = dbQuery.Where(e => e.Category.Name == categoryName);

            if (freeOnly == true)
                dbQuery = dbQuery.Where(e => e.Price == 0);
            else if (maxPrice.HasValue)
                dbQuery = dbQuery.Where(e => e.Price <= maxPrice.Value);

            if (!string.IsNullOrWhiteSpace(timePeriod) && timePeriod != "Tümü" && timePeriod != "Tumu" && timePeriod != "All")
            {
                var normalizedPeriod = timePeriod
                    .Replace("\u00fc", "u").Replace("\u00dc", "U")
                    .Replace("\u011f", "g").Replace("\u011e", "G")
                    .Replace("\u015f", "s").Replace("\u015e", "S")
                    .Replace("\u0131", "i").Replace("\u0130", "I")
                    .ToLowerInvariant();

                dbQuery = normalizedPeriod switch
                {
                    "bugun" or "bug\u00fcn" => dbQuery.Where(e => e.Date.Date == now.Date),
                    "bu hafta" => dbQuery.Where(e => e.Date >= now && e.Date <= now.AddDays(7)),
                    "bu ay" => dbQuery.Where(e => e.Date.Year == now.Year && e.Date.Month == now.Month),
                    _ => dbQuery
                };
            }

            return await MapToListDto(dbQuery.OrderBy(e => e.Date), currentUserId);
        }

        public async Task<EventDto> GetByIdAsync(Guid id, string currentUserId = null)
        {
            var e = await _context.Events
                .Include(x => x.Club)
                    .ThenInclude(c => c.Followers)
                .Include(x => x.Category)
                .Include(x => x.Likes)
                .Include(x => x.Tickets)
                .Include(x => x.Comments)
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (e == null) return null;

            var owner = !string.IsNullOrWhiteSpace(e.OwnerId)
                ? await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == e.OwnerId)
                : null;
            var organizerName = e.Club?.Name ?? BuildUserName(owner);
            var organizerInitials = e.Club?.Initials ?? BuildInitials(organizerName);

            return new EventDto
            {
                Id = e.Id,
                Title = e.Title,
                Description = e.Description,
                Date = e.Date,
                Location = e.Location,
                Address = e.Address,
                Price = e.Price,
                Quota = e.Quota,
                RemainingQuota = e.Quota - (e.Tickets?.Count ?? 0),
                ImageUrl = e.ImageUrl,
                IsActive = e.IsActive,
                OwnerId = e.OwnerId,
                OrganizerName = organizerName,
                OrganizerInitials = organizerInitials,
                OrganizerProfileImageUrl = owner?.ProfileImageUrl,
                CategoryId = e.CategoryId,
                CategoryName = e.Category?.Name,
                ClubId = e.ClubId,
                ClubName = organizerName,
                ClubInitials = organizerInitials,
                IsClubFollowedByCurrentUser = currentUserId != null && (e.Club?.Followers?.Any(f => f.ApplicationUserId == currentUserId) ?? false),
                LikeCount = e.Likes?.Count ?? 0,
                CommentCount = e.Comments?.Count ?? 0,
                TicketCount = e.Tickets?.Count ?? 0,
                IsLikedByCurrentUser = currentUserId != null && (e.Likes?.Any(l => l.ApplicationUserId == currentUserId) ?? false),
                HasTicket = currentUserId != null && (e.Tickets?.Any(t => t.ApplicationUserId == currentUserId) ?? false)
            };
        }

        public async Task<IEnumerable<EventListDto>> GetByClubAsync(string clubId, string currentUserId = null)
        {
            var query = BaseListQuery()
                .Where(e => e.ClubId == clubId)
                .OrderBy(e => e.Date);

            return await MapToListDto(query, currentUserId);
        }

        public async Task<IEnumerable<EventListDto>> GetByOwnerAsync(string ownerId, string currentUserId = null)
        {
            var query = BaseListQuery()
                .Where(e => e.OwnerId == ownerId)
                .OrderBy(e => e.Date);

            return await MapToListDto(query, currentUserId);
        }

        public async Task<IEnumerable<EventListDto>> GetAttendedByUserAsync(string userId, string currentUserId = null)
        {
            var attendedEventIds = await _context.Tickets
                .Where(t => t.ApplicationUserId == userId)
                .Select(t => t.EventId)
                .Distinct()
                .ToListAsync();

            var query = BaseListQuery()
                .Where(e => attendedEventIds.Contains(e.Id))
                .OrderBy(e => e.Date);

            return await MapToListDto(query, currentUserId);
        }

        public async Task<Event> CreateAsync(Event entity)
        {
            _context.Events.Add(entity);
            await _context.SaveChangesAsync();
            return entity;
        }

        public async Task UpdateAsync(Guid id, Event entity)
        {
            var existing = await _context.Events.FindAsync(id);
            if (existing == null) return;

            existing.Title = entity.Title;
            existing.Description = entity.Description;
            existing.Date = entity.Date;
            existing.Location = entity.Location;
            existing.Address = entity.Address;
            existing.Price = entity.Price;
            existing.Quota = entity.Quota;
            existing.ImageUrl = entity.ImageUrl;
            existing.CategoryId = entity.CategoryId;
            existing.IsActive = entity.IsActive;

            _context.Events.Update(existing);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var entity = await _context.Events.FindAsync(id);
            if (entity != null)
            {
                _context.Events.Remove(entity);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> LikeAsync(Guid eventId, string userId)
        {
            var existing = await _context.EventLikes
                .FirstOrDefaultAsync(l => l.EventId == eventId && l.ApplicationUserId == userId);

            if (existing != null)
            {
                _context.EventLikes.Remove(existing);
                await _context.SaveChangesAsync();
                return false;
            }

            _context.EventLikes.Add(new EventLike
            {
                EventId = eventId,
                ApplicationUserId = userId,
                LikedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ExistsAsync(Guid id)
        {
            return await _context.Events.AnyAsync(e => e.Id == id);
        }

        private IQueryable<Event> BaseListQuery()
        {
            return _context.Events
                .Where(e => e.IsActive)
                .Include(e => e.Club)
                .Include(e => e.Category)
                .Include(e => e.Likes)
                .Include(e => e.Tickets)
                .AsNoTracking();
        }

        private static IQueryable<Event> ApplyCreatorTypeFilter(IQueryable<Event> query, string creatorType)
        {
            if (string.IsNullOrWhiteSpace(creatorType)) return query;

            var normalized = creatorType.Trim().ToLowerInvariant();
            return normalized switch
            {
                "club" or "clubevent" or "clubs" => query.Where(e => e.ClubId != null),
                "individual" or "student" or "personal" or "bireysel" => query.Where(e => e.ClubId == null),
                _ => query
            };
        }

        private async Task<List<EventListDto>> MapToListDto(IQueryable<Event> query, string currentUserId)
        {
            var events = await query.ToListAsync();
            var ownerIds = events
                .Select(e => e.OwnerId)
                .Where(id => !string.IsNullOrWhiteSpace(id))
                .Distinct()
                .ToList();

            var owners = await _context.Users
                .Where(u => ownerIds.Contains(u.Id))
                .AsNoTracking()
                .ToDictionaryAsync(u => u.Id);

            return events.Select(e =>
            {
                var owner = owners.TryGetValue(e.OwnerId ?? "", out var foundOwner) ? foundOwner : null;
                var organizerName = e.Club?.Name ?? BuildUserName(owner);
                return new EventListDto
                {
                    Id = e.Id,
                    Title = e.Title,
                    OwnerId = e.OwnerId,
                    OrganizerName = organizerName,
                    OrganizerInitials = e.Club?.Initials ?? BuildInitials(organizerName),
                    OrganizerProfileImageUrl = owner?.ProfileImageUrl,
                    ClubId = e.ClubId,
                    ClubName = organizerName,
                    CategoryName = e.Category?.Name,
                    Price = e.Price,
                    Date = e.Date,
                    ImageUrl = e.ImageUrl,
                    LikeCount = e.Likes?.Count ?? 0,
                    IsLikedByCurrentUser = currentUserId != null && (e.Likes?.Any(l => l.ApplicationUserId == currentUserId) ?? false)
                };
            }).ToList();
        }

        private static string BuildUserName(ApplicationUser user)
        {
            if (user == null) return "Kullanici Etkinligi";
            var fullName = $"{user.FirstName} {user.LastName}".Trim();
            return string.IsNullOrWhiteSpace(fullName) ? user.UserName : fullName;
        }

        private static string BuildInitials(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "KE";
            var parts = value.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            return parts.Length >= 2
                ? $"{parts[0][0]}{parts[^1][0]}".ToUpper()
                : value.Substring(0, Math.Min(2, value.Length)).ToUpper();
        }
    }
}
