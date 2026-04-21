using System;

namespace CleanArchitecture.Core.DTOs.Event
{
    public class EventDto
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public DateTime Date { get; set; }
        public string Location { get; set; }
        public string Address { get; set; }
        public decimal Price { get; set; }
        public int Quota { get; set; }
        public int RemainingQuota { get; set; }
        public string ImageUrl { get; set; }
        public bool IsActive { get; set; }
        public Guid? CategoryId { get; set; }
        public string CategoryName { get; set; }
        public string OwnerId { get; set; }
        public string OrganizerName { get; set; }
        public string OrganizerInitials { get; set; }
        public string OrganizerProfileImageUrl { get; set; }
        public string ClubId { get; set; }
        public string ClubName { get; set; }
        public string ClubInitials { get; set; }
        public bool IsClubFollowedByCurrentUser { get; set; }
        public int LikeCount { get; set; }
        public int CommentCount { get; set; }
        public int TicketCount { get; set; }
        public bool IsLikedByCurrentUser { get; set; }
        public bool HasTicket { get; set; }
    }

    public class CreateEventDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public DateTime Date { get; set; }
        public string Location { get; set; }
        public string Address { get; set; }
        public decimal Price { get; set; }
        public int Quota { get; set; }
        public string ImageUrl { get; set; }
        public Guid? CategoryId { get; set; }
        public string ClubId { get; set; }
    }

    public class UpdateEventDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public DateTime Date { get; set; }
        public string Location { get; set; }
        public string Address { get; set; }
        public decimal Price { get; set; }
        public int Quota { get; set; }
        public string ImageUrl { get; set; }
        public Guid? CategoryId { get; set; }
        public bool IsActive { get; set; }
    }

    public class EventListDto
    {
        public Guid Id { get; set; }
        public string Title { get; set; }
        public string OwnerId { get; set; }
        public string OrganizerName { get; set; }
        public string OrganizerInitials { get; set; }
        public string OrganizerProfileImageUrl { get; set; }
        public string ClubId { get; set; }
        public string ClubName { get; set; }
        public string CategoryName { get; set; }
        public decimal Price { get; set; }
        public DateTime Date { get; set; }
        public string ImageUrl { get; set; }
        public int LikeCount { get; set; }
        public bool IsLikedByCurrentUser { get; set; }
    }
}
