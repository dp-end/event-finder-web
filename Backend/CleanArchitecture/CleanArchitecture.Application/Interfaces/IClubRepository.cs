using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Club;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CleanArchitecture.Core.Interfaces
{
    public interface IClubRepository
    {
        Task<IEnumerable<ClubListDto>> GetAllAsync(string currentUserId = null);
        Task<IEnumerable<ClubListDto>> GetPopularAsync(int count, string currentUserId = null);
        Task<ClubDto> GetByIdAsync(string id, string currentUserId = null);
        Task<Club> CreateAsync(Club entity);
        Task UpdateAsync(string id, Club entity);
        Task DeleteAsync(string id);
        Task<bool> FollowAsync(string clubId, string userId);  // true = takip edildi, false = takip bırakıldı
        Task<bool> ExistsAsync(string id);
    }
}
