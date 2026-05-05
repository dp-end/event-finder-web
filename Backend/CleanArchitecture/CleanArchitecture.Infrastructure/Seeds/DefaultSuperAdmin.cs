using CleanArchitecture.Application.Entities;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;

namespace CleanArchitecture.Infrastructure.Seeds
{
    public static class DefaultSuperAdmin
    {
        // SuperAdmin/Admin/Moderator rolleri kaldırıldı. Seed artık boş.
        public static Task SeedAsync(UserManager<ApplicationUser> _, RoleManager<IdentityRole> __)
            => Task.CompletedTask;
    }
}
