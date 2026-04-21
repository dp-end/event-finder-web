using System.Security.Claims;

namespace CleanArchitecture.WebApi.Extensions
{
    public static class ClaimsPrincipalExtensions
    {
        public static string FindUserId(this ClaimsPrincipal user)
        {
            return user?.FindFirstValue("uid")
                ?? user?.FindFirstValue(ClaimTypes.NameIdentifier);
        }
    }
}
