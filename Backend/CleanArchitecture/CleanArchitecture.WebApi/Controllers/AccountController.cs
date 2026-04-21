using CleanArchitecture.Application.Entities;
using CleanArchitecture.Core.DTOs.Account;
using CleanArchitecture.Core.Enums;
using CleanArchitecture.Core.Interfaces;
using CleanArchitecture.Infrastructure.Contexts;
using CleanArchitecture.WebApi.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AccountController : ControllerBase
    {
        private readonly IAccountService _accountService;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ApplicationDbContext _context;

        public AccountController(
            IAccountService accountService,
            UserManager<ApplicationUser> userManager,
            ApplicationDbContext context)
        {
            _accountService = accountService;
            _userManager = userManager;
            _context = context;
        }

        [HttpPost("authenticate")]
        public async Task<IActionResult> AuthenticateAsync(AuthenticationRequest request)
        {
            return Ok(await _accountService.AuthenticateAsync(request, GenerateIPAddress()));
        }

        [HttpPost("register")]
        public async Task<IActionResult> RegisterAsync(RegisterRequest request)
        {
            var origin = Request.Headers["origin"];
            return Ok(await _accountService.RegisterAsync(request, origin));
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> Me()
        {
            var user = await GetCurrentUserAsync();
            if (user == null) return Unauthorized();

            return Ok(await BuildProfileDto(user));
        }

        [HttpGet("public/{userId}")]
        public async Task<IActionResult> PublicProfile(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId)) return BadRequest(new { message = "Kullanici id bos olamaz." });

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return NotFound(new { message = "Kullanici bulunamadi." });

            var profile = await BuildProfileDto(user);
            profile.Email = null;
            return Ok(profile);
        }

        [HttpPut("profile")]
        [Authorize]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        {
            var user = await GetCurrentUserAsync();
            if (user == null) return Unauthorized();

            var roles = await _userManager.GetRolesAsync(user);
            var isClub = roles.Contains(Roles.Club.ToString());

            if (isClub)
            {
                var club = user as Club
                    ?? await _context.Clubs.FirstOrDefaultAsync(c => c.Id == user.Id || c.AdminUserId == user.Id);
                if (club == null) return BadRequest(new { message = "Kulup kaydi bulunamadi." });

                if (!string.IsNullOrWhiteSpace(request.ClubName))
                {
                    club.Name = request.ClubName.Trim();
                    club.Initials = BuildInitials(club.Name);
                    user.FirstName = club.Name;
                    user.LastName = "";
                }

                club.Description = request.ClubDescription ?? club.Description;
                club.CoverImageUrl = request.ClubCoverImageUrl ?? club.CoverImageUrl;
                club.InstagramHandle = request.ClubInstagramHandle ?? club.InstagramHandle;
                club.University = request.University ?? club.University;
                club.Department = request.Department ?? club.Department;
                club.ProfileImageUrl = request.ProfileImageUrl ?? club.ProfileImageUrl;
                if (!ReferenceEquals(user, club))
                {
                    _context.Clubs.Update(club);
                }
            }
            else
            {
                user.FirstName = request.FirstName ?? user.FirstName;
                user.LastName = request.LastName ?? user.LastName;

                user.University = request.University ?? user.University;
                user.Department = request.Department ?? user.Department;
                user.ProfileImageUrl = request.ProfileImageUrl ?? user.ProfileImageUrl;
            }

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
            {
                return BadRequest(new { message = string.Join(", ", result.Errors.Select(e => e.Description)) });
            }

            await _context.SaveChangesAsync();
            return Ok(await BuildProfileDto(user));
        }

        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var user = await GetCurrentUserAsync();
            if (user == null) return Unauthorized();

            if (string.IsNullOrWhiteSpace(request.CurrentPassword) || string.IsNullOrWhiteSpace(request.NewPassword))
                return BadRequest(new { message = "Mevcut ve yeni şifre boş olamaz." });

            if (request.NewPassword.Length < 6)
                return BadRequest(new { message = "Yeni şifre en az 6 karakter olmalıdır." });

            var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
            if (!result.Succeeded)
                return BadRequest(new { message = string.Join(", ", result.Errors.Select(e => e.Description)) });

            return Ok(new { message = "Şifreniz başarıyla değiştirildi." });
        }

        [HttpGet("confirm-email")]
        public async Task<IActionResult> ConfirmEmailAsync([FromQuery] string userId, [FromQuery] string code)
        {
            return Ok(await _accountService.ConfirmEmailAsync(userId, code));
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest model)
        {
            var origin = Request.Headers["origin"].FirstOrDefault() ?? "https://localhost:9001";
            var result = await _accountService.ForgotPassword(model, origin);
            return Ok(result);
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword(ResetPasswordRequest model)
        {
            return Ok(await _accountService.ResetPassword(model));
        }

        private async Task<ApplicationUser> GetCurrentUserAsync()
        {
            var userId = User.FindUserId();
            return string.IsNullOrWhiteSpace(userId) ? null : await _userManager.FindByIdAsync(userId);
        }

        private async Task<ProfileDto> BuildProfileDto(ApplicationUser user)
        {
            var roles = await _userManager.GetRolesAsync(user);
            var isClub = roles.Contains(Roles.Club.ToString());
            var club = isClub
                ? await _context.Clubs.AsNoTracking().FirstOrDefaultAsync(c => c.Id == user.Id || c.AdminUserId == user.Id)
                : null;

            return new ProfileDto
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                UserName = user.UserName,
                University = user.University,
                Department = user.Department,
                ProfileImageUrl = user.ProfileImageUrl,
                UserType = isClub ? "club" : "student",
                ClubId = club?.Id,
                ClubName = club?.Name,
                ClubDescription = club?.Description,
                ClubCoverImageUrl = club?.CoverImageUrl,
                ClubInstagramHandle = club?.InstagramHandle,
                TicketCount = await _context.Tickets.CountAsync(t => t.ApplicationUserId == user.Id),
                FollowingClubCount = await _context.ClubFollowers.CountAsync(f => f.ApplicationUserId == user.Id),
                CreatedEventCount = await _context.Events.CountAsync(e => e.OwnerId == user.Id && e.IsActive),
                ClubFollowerCount = club == null ? 0 : await _context.ClubFollowers.CountAsync(f => f.ClubId == club.Id)
            };
        }

        private static string BuildInitials(string name)
        {
            if (string.IsNullOrWhiteSpace(name)) return "KL";
            var words = name.Split(' ', System.StringSplitOptions.RemoveEmptyEntries);
            return words.Length >= 2
                ? $"{words[0][0]}{words[1][0]}".ToUpper()
                : name.Substring(0, System.Math.Min(2, name.Length)).ToUpper();
        }

        private string GenerateIPAddress()
        {
            if (Request.Headers.ContainsKey("X-Forwarded-For"))
                return Request.Headers["X-Forwarded-For"];

            return HttpContext.Connection.RemoteIpAddress.MapToIPv4().ToString();
        }
    }
}
