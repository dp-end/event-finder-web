using CleanArchitecture.Core.Enums;
using CleanArchitecture.Application.Entities;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;

namespace CleanArchitecture.Infrastructure.Seeds
{
    public static class DefaultRoles
    {
        public static async Task SeedAsync(UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager)
        {
            foreach (var role in new[]
            {
                Roles.SuperAdmin,
                Roles.Admin,
                Roles.Moderator,
                Roles.Basic,
                Roles.Club
            })
            {
                var roleName = role.ToString();
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    await roleManager.CreateAsync(new IdentityRole(roleName));
                }
            }
        }
    }
}
