namespace CleanArchitecture.Core.DTOs.Account
{
    public class ProfileDto
    {
        public string Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string UserName { get; set; }
        public string University { get; set; }
        public string Department { get; set; }
        public string ProfileImageUrl { get; set; }
        public string UserType { get; set; }
        public string ClubId { get; set; }
        public string ClubName { get; set; }
        public string ClubDescription { get; set; }
        public string ClubCoverImageUrl { get; set; }
        public string ClubInstagramHandle { get; set; }
        public int TicketCount { get; set; }
        public int FollowingClubCount { get; set; }
        public int CreatedEventCount { get; set; }
        public int ClubFollowerCount { get; set; }
    }

    public class UpdateProfileRequest
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string University { get; set; }
        public string Department { get; set; }
        public string ProfileImageUrl { get; set; }
        public string ClubName { get; set; }
        public string ClubDescription { get; set; }
        public string ClubCoverImageUrl { get; set; }
        public string ClubInstagramHandle { get; set; }
    }
}
