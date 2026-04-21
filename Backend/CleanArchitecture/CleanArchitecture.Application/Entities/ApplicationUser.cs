using CleanArchitecture.Core.DTOs.Account;
using Microsoft.AspNetCore.Identity;
using System.Collections.Generic;

namespace CleanArchitecture.Application.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Department { get; set; }
        public string University { get; set; }
        public string ProfileImageUrl { get; set; }

        public ICollection<Ticket> Tickets { get; set; }
        public List<RefreshToken> RefreshTokens { get; set; }

        public bool OwnsToken(string token)
        {
            return RefreshTokens?.Find(x => x.Token == token) != null;
        }
    }
}
