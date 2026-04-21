using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Http;

namespace CleanArchitecture.WebApi.Services
{
    public class AuthenticatedUserService : IAuthenticatedUserService
    {
        public AuthenticatedUserService(IHttpContextAccessor httpContextAccessor)
        {
            UserId = httpContextAccessor.HttpContext?.User?.FindUserId();
        }

        public string UserId { get; }
    }
}
