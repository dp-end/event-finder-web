using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace CleanArchitecture.Application.Entities
{
    public enum NotificationType
    {
        NewEvent = 1,
        TicketPurchased = 2,
        EventReminder = 3,
        EventCancelled = 4,
        ClubNewEvent = 5,
        General = 6,
        ClubFollowed = 7,
        EventCommented = 8,
        EventLiked = 9
    }

    public class Notification
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Title { get; set; }
        public string Body { get; set; }
        public bool IsRead { get; set; } = false;
        public NotificationType Type { get; set; } = NotificationType.General;

        // Opsiyonel: ilgili etkinlik veya kulüp ID'si (deep link için)
        public Guid? RelatedEventId { get; set; }
        public string RelatedClubId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Kime ait bildirim
        public string ApplicationUserId { get; set; }

        [NotMapped]
        public string UserId => ApplicationUserId;

        [NotMapped]
        public string Message => Body;

        [NotMapped]
        public string RelatedEntityId => !string.IsNullOrWhiteSpace(RelatedClubId)
            ? RelatedClubId
            : RelatedEventId?.ToString();
    }
}
