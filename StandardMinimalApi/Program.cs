var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Disable HTTPS redirection for this demo
// app.UseHttpsRedirection();

app.MapGet("/users", () =>
{
    var firstNames = new[] { "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Barbara", "David", "Elizabeth", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Christopher", "Karen" };
    var lastNames = new[] { "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin" };
    var cities = new[] { "New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville", "Fort Worth", "Columbus", "Indianapolis", "Charlotte", "San Francisco", "Seattle", "Denver", "Washington" };
    var streets = new[] { "Main Street", "Oak Avenue", "Maple Drive", "Cedar Lane", "Pine Road", "Elm Street", "Washington Boulevard", "Park Avenue", "Lake Drive", "Hill Street", "River Road", "Forest Lane", "Spring Street", "Valley Road", "Mountain View", "Sunset Boulevard", "Broadway", "First Avenue", "Second Street", "Third Avenue" };
    var companies = new[] { "TechCorp", "GlobalSystems", "DataWorks", "CloudNine", "InnovateLabs", "FutureSync", "AlphaTech", "BetaSoft", "GammaIndustries", "DeltaSolutions", "EpsilonGroup", "ZetaDigital", "EtaTechnologies", "ThetaVentures", "IotaEnterprises" };
    var departments = new[] { "Engineering", "Sales", "Marketing", "Human Resources", "Finance", "Operations", "Customer Support", "Product Management", "Research and Development", "Quality Assurance", "Legal", "IT Support", "Business Development", "Accounting", "Administration" };
    var positions = new[] { "Software Engineer", "Senior Developer", "Product Manager", "Sales Representative", "Marketing Specialist", "HR Manager", "Financial Analyst", "Operations Manager", "Support Specialist", "QA Engineer", "Team Lead", "Director", "Vice President", "Consultant", "Coordinator" };
    var states = new[] { "CA", "NY", "TX", "FL", "PA", "IL", "OH", "GA", "NC", "MI", "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI" };
    var tags = new[] { "VIP", "Premium", "Enterprise", "Verified", "Active", "Beta", "EarlyAdopter", "Ambassador", "Partner", "Influencer", "Champion", "Leader", "Expert", "Mentor", "Contributor" };

    var users = new List<User>();
    var baseDate = new DateTime(2020, 1, 1);

    for (int i = 1; i <= 10000; i++)
    {
        var fnIndex = (i * 7) % firstNames.Length;
        var lnIndex = (i * 11) % lastNames.Length;
        var cityIndex = (i * 13) % cities.Length;
        var streetIndex = (i * 17) % streets.Length;
        var stateIndex = (i * 19) % states.Length;
        var companyIndex = (i * 23) % companies.Length;
        var deptIndex = (i * 29) % departments.Length;
        var posIndex = (i * 31) % positions.Length;

        var firstName = firstNames[fnIndex];
        var lastName = lastNames[lnIndex];
        var email = $"{firstName.ToLower()}.{lastName.ToLower()}{i}@example.com";
        var age = 25 + (i % 50);
        var yearsAtCompany = 1 + (i % 15);

        users.Add(new User
        {
            Id = i,
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            PhoneNumber = $"+1-{(200 + (i % 800)).ToString("D3")}-{(100 + (i % 900)).ToString("D3")}-{(1000 + (i % 9000)).ToString("D4")}",
            DateOfBirth = baseDate.AddYears(-age).AddDays(i % 365),
            Address = new Address
            {
                Street = $"{100 + (i % 9900)} {streets[streetIndex]}",
                City = cities[cityIndex],
                State = states[stateIndex],
                ZipCode = (10000 + (i % 89999)).ToString("D5"),
                Country = "USA"
            },
            Company = new Company
            {
                Name = companies[companyIndex],
                Department = departments[deptIndex],
                Position = positions[posIndex],
                Salary = 40000 + (i % 160000),
                StartDate = baseDate.AddYears(yearsAtCompany).AddDays(i % 365)
            },
            Preferences = new UserPreferences
            {
                Theme = i % 2 == 0 ? "Dark" : "Light",
                Language = (i % 3) switch { 0 => "en", 1 => "es", _ => "fr" },
                NotificationsEnabled = i % 3 != 0,
                Newsletter = i % 4 != 0,
                TwoFactorEnabled = i % 5 == 0
            },
            Metadata = new Dictionary<string, string>
            {
                { "LastLogin", baseDate.AddDays(i % 730).ToString("o") },
                { "AccountStatus", i % 10 == 0 ? "Inactive" : "Active" },
                { "VerificationLevel", ((i % 3) + 1).ToString() },
                { "ReferralCode", $"REF{i:D6}" },
                { "CustomerSince", baseDate.AddMonths(-(i % 60)).ToString("o") }
            },
            Tags = Enumerable.Range(0, 3 + (i % 6))
                .Select(j => tags[(i + j) % tags.Length])
                .Distinct()
                .ToList(),
            IsActive = i % 10 != 0,
            CreatedAt = baseDate.AddDays(i % 1825),
            UpdatedAt = baseDate.AddDays(1825 + (i % 365))
        });
    }

    return users;
})
.WithName("GetUsers");

app.MapGet("/benchmark", () =>
{
    var stopwatch = System.Diagnostics.Stopwatch.StartNew();

    // CPU-intensive task: Calculate prime numbers
    var primes = new List<long>();
    for (var i = 2; i < 1000_000; i++)
    {
        bool isPrime = true;
        for (var j = 2; j * j <= i; j++)
        {
            if (i % j == 0)
            {
                isPrime = false;
                break;
            }
        }
        if (isPrime) primes.Add(i);
    }

    stopwatch.Stop();

    return new BenchmarkResult
    {
        ExecutionTimeMs = stopwatch.ElapsedMilliseconds,
        PrimesFound = primes.Count,
        ProcessId = Environment.ProcessId,
        WorkingSetMB = Environment.WorkingSet / (1024.0 * 1024.0)
    };
})
.WithName("Benchmark");

app.Run();

record BenchmarkResult
{
    public long ExecutionTimeMs { get; init; }
    public int PrimesFound { get; init; }
    public int ProcessId { get; init; }
    public double WorkingSetMB { get; init; }
}

record User
{
    public int Id { get; init; }
    public string FirstName { get; init; } = string.Empty;
    public string LastName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public DateTime DateOfBirth { get; init; }
    public Address Address { get; init; } = new();
    public Company Company { get; init; } = new();
    public UserPreferences Preferences { get; init; } = new();
    public Dictionary<string, string> Metadata { get; init; } = new();
    public List<string> Tags { get; init; } = new();
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}

record Address
{
    public string Street { get; init; } = string.Empty;
    public string City { get; init; } = string.Empty;
    public string State { get; init; } = string.Empty;
    public string ZipCode { get; init; } = string.Empty;
    public string Country { get; init; } = string.Empty;
}

record Company
{
    public string Name { get; init; } = string.Empty;
    public string Department { get; init; } = string.Empty;
    public string Position { get; init; } = string.Empty;
    public decimal Salary { get; init; }
    public DateTime StartDate { get; init; }
}

record UserPreferences
{
    public string Theme { get; init; } = string.Empty;
    public string Language { get; init; } = string.Empty;
    public bool NotificationsEnabled { get; init; }
    public bool Newsletter { get; init; }
    public bool TwoFactorEnabled { get; init; }
}
