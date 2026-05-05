using System;
using System.Collections.Generic;

namespace CleanArchitecture.Core.DTOs.Comment
{
    public class CommentDto
    {
        public Guid Id { get; set; }
        public string Content { get; set; }
        public DateTime CreatedAt { get; set; }
        public string UserFullName { get; set; }
        public string UserInitials { get; set; }
        public string UserProfileImageUrl { get; set; }
        public string ApplicationUserId { get; set; }
        public Guid? ParentCommentId { get; set; }
        public string ReplyToUserName { get; set; }
        public List<CommentDto> Replies { get; set; } = new List<CommentDto>();
    }

    public class CreateCommentDto
    {
        public Guid EventId { get; set; }
        public string Content { get; set; }
        public Guid? ParentCommentId { get; set; }
    }
}
