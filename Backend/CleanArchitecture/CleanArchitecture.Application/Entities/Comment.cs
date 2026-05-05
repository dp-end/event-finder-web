using System;
using System.Collections.Generic;

namespace CleanArchitecture.Application.Entities
{
    public class Comment
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Content { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public Guid EventId { get; set; }
        public Event Event { get; set; }

        public Guid? ParentCommentId { get; set; }
        public Comment ParentComment { get; set; }
        public ICollection<Comment> Replies { get; set; }

        public string ApplicationUserId { get; set; }
        public string UserFullName { get; set; }
        public string UserInitials { get; set; }
    }
}
