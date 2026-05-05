using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Comment;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CleanArchitecture.Infrastructure.Repositories
{
    public class CommentRepository : ICommentRepository
    {
        private readonly ApplicationDbContext _context;

        public CommentRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<CommentDto>> GetByEventAsync(Guid eventId)
        {
            var comments = await _context.Comments
                .Where(c => c.EventId == eventId)
                .OrderByDescending(c => c.CreatedAt)
                .AsNoTracking()
                .ToListAsync();

            var userIds = comments
                .Select(c => c.ApplicationUserId)
                .Where(id => !string.IsNullOrWhiteSpace(id))
                .Distinct()
                .ToList();

            var users = await _context.Users
                .Where(u => userIds.Contains(u.Id))
                .AsNoTracking()
                .ToDictionaryAsync(u => u.Id);

            var byId = comments.ToDictionary(c => c.Id);
            var dtoById = comments.ToDictionary(
                c => c.Id,
                c => MapToDto(
                    c,
                    users.TryGetValue(c.ApplicationUserId ?? "", out var user) ? user : null,
                    c.ParentCommentId.HasValue && byId.TryGetValue(c.ParentCommentId.Value, out var parent)
                        ? parent.UserFullName
                        : null));

            foreach (var dto in dtoById.Values)
            {
                if (dto.ParentCommentId.HasValue && dtoById.TryGetValue(dto.ParentCommentId.Value, out var parentDto))
                {
                    parentDto.Replies.Add(dto);
                }
            }

            foreach (var dto in dtoById.Values)
            {
                dto.Replies = dto.Replies.OrderBy(r => r.CreatedAt).ToList();
            }

            return dtoById.Values
                .Where(c => c.ParentCommentId == null)
                .OrderByDescending(c => c.CreatedAt)
                .ToList();
        }

        public async Task<CommentDto> AddAsync(CreateCommentDto dto, string userId, string userFullName, string userInitials)
        {
            Comment parent = null;
            if (dto.ParentCommentId.HasValue)
            {
                parent = await _context.Comments
                    .AsNoTracking()
                    .FirstOrDefaultAsync(c => c.Id == dto.ParentCommentId.Value && c.EventId == dto.EventId);
            }

            var comment = new Comment
            {
                Id = Guid.NewGuid(),
                EventId = dto.EventId,
                ParentCommentId = parent?.Id,
                Content = dto.Content,
                ApplicationUserId = userId,
                UserFullName = userFullName,
                UserInitials = userInitials,
                CreatedAt = DateTime.UtcNow
            };

            _context.Comments.Add(comment);
            await _context.SaveChangesAsync();

            var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
            return MapToDto(comment, user, parent?.UserFullName);
        }

        public async Task DeleteAsync(Guid commentId, string userId)
        {
            var comment = await _context.Comments
                .FirstOrDefaultAsync(c => c.Id == commentId && c.ApplicationUserId == userId);

            if (comment == null) return;

            var replies = await _context.Comments
                .Where(c => c.ParentCommentId == commentId)
                .ToListAsync();

            if (replies.Count > 0)
            {
                _context.Comments.RemoveRange(replies);
            }

            _context.Comments.Remove(comment);
            await _context.SaveChangesAsync();
        }

        private static CommentDto MapToDto(Comment comment, ApplicationUser user, string replyToUserName)
        {
            return new CommentDto
            {
                Id = comment.Id,
                Content = comment.Content,
                CreatedAt = comment.CreatedAt,
                UserFullName = comment.UserFullName,
                UserInitials = comment.UserInitials,
                UserProfileImageUrl = user?.ProfileImageUrl,
                ApplicationUserId = comment.ApplicationUserId,
                ParentCommentId = comment.ParentCommentId,
                ReplyToUserName = replyToUserName,
                Replies = new List<CommentDto>()
            };
        }
    }
}
