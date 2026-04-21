# Backend Configuration

The committed `appsettings.json` intentionally contains no production database, SMTP, or JWT secrets.

For local MySQL development, copy:

```powershell
Copy-Item CleanArchitecture\CleanArchitecture.WebApi\appsettings.Development.example.json CleanArchitecture\CleanArchitecture.WebApi\appsettings.Development.json
```

Then replace the placeholder values in `appsettings.Development.json`.

Important: if `UseInMemoryDatabase` is `true`, the app writes to a temporary in-memory database. Registrations, events, comments, likes, and tickets will not appear in MySQL and will be lost when the backend restarts.

You can also use environment variables. ASP.NET Core maps nested values with double underscores:

```powershell
$env:UseInMemoryDatabase="false"
$env:ConnectionStrings__DefaultConnection="Server=localhost;Port=3306;Database=eventfinder;Uid=eventfinder_user;Pwd=your-password;SslMode=None;"
$env:JWTSettings__Key="your-private-key-at-least-32-characters-long"
```

Or use user-secrets from `Backend/CleanArchitecture/CleanArchitecture.WebApi`:

```powershell
dotnet user-secrets set "UseInMemoryDatabase" "false"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Port=3306;Database=eventfinder;Uid=eventfinder_user;Pwd=your-password;SslMode=None;"
dotnet user-secrets set "JWTSettings:Key" "your-private-key-at-least-32-characters-long"
```

The previously committed database, SMTP, and JWT values must be treated as compromised and rotated.
