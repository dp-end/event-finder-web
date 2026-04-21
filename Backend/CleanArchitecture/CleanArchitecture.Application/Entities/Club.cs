using System.Collections.Generic;

namespace CleanArchitecture.Application.Entities
{
    public class Club : ApplicationUser
    {
        public string Name { get; set; }
        public string Initials { get; set; }           // Kısaltma (ör: TI, MS, AA)
        public string Category { get; set; }           // Kulübün ana kategorisi
        public string Description { get; set; }
        public string CoverImageUrl { get; set; }
        public string InstagramHandle { get; set; }
        public string AdvisorName { get; set; }
        public string ReferenceNumber { get; set; }

        // Kulüp yöneticisinin kullanıcı ID'si (isteğe bağlı)
        public string AdminUserId { get; set; }

        // Bir kulübün birden fazla etkinliği olabilir
        public ICollection<Event> Events { get; set; }

        // Kulübü takip eden kullanıcılar
        public ICollection<ClubFollower> Followers { get; set; }
    }
}
