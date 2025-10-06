use actix_web::{HttpResponse, Responder};
use chrono::NaiveDate;
use std::collections::HashMap;
use std::time::Instant;
use sysinfo::System;

use crate::models::{Address, BenchmarkResult, Company, User, UserPreferences};

pub async fn get_users() -> impl Responder {
    // Use static arrays to avoid repeated allocations
    static FIRST_NAMES: &[&str] = &[
        "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
        "William", "Barbara", "David", "Elizabeth", "Richard", "Susan", "Joseph", "Jessica",
        "Thomas", "Sarah", "Christopher", "Karen",
    ];
    static LAST_NAMES: &[&str] = &[
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
        "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
        "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    ];
    static CITIES: &[&str] = &[
        "New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia",
        "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville",
        "Fort Worth", "Columbus", "Indianapolis", "Charlotte", "San Francisco", "Seattle",
        "Denver", "Washington",
    ];
    static STREETS: &[&str] = &[
        "Main Street", "Oak Avenue", "Maple Drive", "Cedar Lane", "Pine Road", "Elm Street",
        "Washington Boulevard", "Park Avenue", "Lake Drive", "Hill Street", "River Road",
        "Forest Lane", "Spring Street", "Valley Road", "Mountain View", "Sunset Boulevard",
        "Broadway", "First Avenue", "Second Street", "Third Avenue",
    ];
    static COMPANIES: &[&str] = &[
        "TechCorp", "GlobalSystems", "DataWorks", "CloudNine", "InnovateLabs", "FutureSync",
        "AlphaTech", "BetaSoft", "GammaIndustries", "DeltaSolutions", "EpsilonGroup",
        "ZetaDigital", "EtaTechnologies", "ThetaVentures", "IotaEnterprises",
    ];
    static DEPARTMENTS: &[&str] = &[
        "Engineering", "Sales", "Marketing", "Human Resources", "Finance", "Operations",
        "Customer Support", "Product Management", "Research and Development",
        "Quality Assurance", "Legal", "IT Support", "Business Development", "Accounting",
        "Administration",
    ];
    static POSITIONS: &[&str] = &[
        "Software Engineer", "Senior Developer", "Product Manager", "Sales Representative",
        "Marketing Specialist", "HR Manager", "Financial Analyst", "Operations Manager",
        "Support Specialist", "QA Engineer", "Team Lead", "Director", "Vice President",
        "Consultant", "Coordinator",
    ];
    static STATES: &[&str] = &[
        "CA", "NY", "TX", "FL", "PA", "IL", "OH", "GA", "NC", "MI", "NJ", "VA", "WA", "AZ",
        "MA", "TN", "IN", "MO", "MD", "WI",
    ];
    static TAGS: &[&str] = &[
        "VIP", "Premium", "Enterprise", "Verified", "Active", "Beta", "EarlyAdopter",
        "Ambassador", "Partner", "Influencer", "Champion", "Leader", "Expert", "Mentor",
        "Contributor",
    ];

    let mut users = Vec::with_capacity(10000);
    let base_date = NaiveDate::from_ymd_opt(2020, 1, 1).unwrap();

    for i in 1..=10000 {
        let fn_index = (i * 7) % FIRST_NAMES.len();
        let ln_index = (i * 11) % LAST_NAMES.len();
        let city_index = (i * 13) % CITIES.len();
        let street_index = (i * 17) % STREETS.len();
        let state_index = (i * 19) % STATES.len();
        let company_index = (i * 23) % COMPANIES.len();
        let dept_index = (i * 29) % DEPARTMENTS.len();
        let pos_index = (i * 31) % POSITIONS.len();

        let first_name = FIRST_NAMES[fn_index];
        let last_name = LAST_NAMES[ln_index];
        let email = format!(
            "{}.{}{}@example.com",
            first_name.to_lowercase(),
            last_name.to_lowercase(),
            i
        );
        let age = 25 + (i % 50);
        let years_at_company = 1 + (i % 15);

        let date_of_birth = base_date
            .checked_sub_signed(chrono::Duration::days((age * 365 + (i % 365)) as i64))
            .unwrap();
        let created_at = base_date
            .checked_add_signed(chrono::Duration::days((i % 1825) as i64))
            .unwrap();
        let updated_at = base_date
            .checked_add_signed(chrono::Duration::days((1825 + (i % 365)) as i64))
            .unwrap();
        let start_date = base_date
            .checked_add_signed(chrono::Duration::days(
                (years_at_company * 365 + (i % 365)) as i64,
            ))
            .unwrap();

        let mut metadata = HashMap::with_capacity(5);
        let last_login = base_date
            .checked_add_signed(chrono::Duration::days((i % 730) as i64))
            .unwrap();
        metadata.insert(
            "LastLogin".to_string(),
            format!("{}T00:00:00Z", last_login.format("%Y-%m-%d")),
        );
        metadata.insert(
            "AccountStatus".to_string(),
            if i % 10 == 0 {
                "Inactive".to_string()
            } else {
                "Active".to_string()
            },
        );
        metadata.insert("VerificationLevel".to_string(), ((i % 3) + 1).to_string());
        metadata.insert("ReferralCode".to_string(), format!("REF{:06}", i));
        let customer_since = base_date
            .checked_sub_signed(chrono::Duration::days(((i % 60) * 30) as i64))
            .unwrap();
        metadata.insert(
            "CustomerSince".to_string(),
            format!("{}T00:00:00Z", customer_since.format("%Y-%m-%d")),
        );

        let mut user_tags: Vec<String> = (0..(3 + (i % 6)))
            .map(|j| TAGS[(i + j) % TAGS.len()].to_string())
            .collect();
        user_tags.sort();
        user_tags.dedup();

        users.push(User {
            id: i as i32,
            first_name: first_name.to_string(),
            last_name: last_name.to_string(),
            email,
            phone_number: format!(
                "+1-{:03}-{:03}-{:04}",
                200 + (i % 800),
                100 + (i % 900),
                1000 + (i % 9000)
            ),
            date_of_birth: format!("{}T00:00:00Z", date_of_birth.format("%Y-%m-%d")),
            address: Address {
                street: format!("{} {}", 100 + (i % 9900), STREETS[street_index]),
                city: CITIES[city_index].to_string(),
                state: STATES[state_index].to_string(),
                zip_code: format!("{:05}", 10000 + (i % 89999)),
                country: "USA".to_string(),
            },
            company: Company {
                name: COMPANIES[company_index].to_string(),
                department: DEPARTMENTS[dept_index].to_string(),
                position: POSITIONS[pos_index].to_string(),
                salary: (40000 + (i % 160000)) as f64,
                start_date: format!("{}T00:00:00Z", start_date.format("%Y-%m-%d")),
            },
            preferences: UserPreferences {
                theme: if i % 2 == 0 {
                    "Dark".to_string()
                } else {
                    "Light".to_string()
                },
                language: match i % 3 {
                    0 => "en".to_string(),
                    1 => "es".to_string(),
                    _ => "fr".to_string(),
                },
                notifications_enabled: i % 3 != 0,
                newsletter: i % 4 != 0,
                two_factor_enabled: i % 5 == 0,
            },
            metadata,
            tags: user_tags,
            is_active: i % 10 != 0,
            created_at: format!("{}T00:00:00Z", created_at.format("%Y-%m-%d")),
            updated_at: format!("{}T00:00:00Z", updated_at.format("%Y-%m-%d")),
        });
    }

    HttpResponse::Ok().json(users)
}

pub async fn benchmark() -> impl Responder {
    let start = Instant::now();

    // CPU-intensive task: Calculate prime numbers using Sieve of Eratosthenes
    let limit = 1_000_000;
    let mut is_prime = vec![true; limit];
    is_prime[0] = false;
    if limit > 1 {
        is_prime[1] = false;
    }

    let sqrt_limit = (limit as f64).sqrt() as usize;
    for i in 2..=sqrt_limit {
        if is_prime[i] {
            let mut j = i * i;
            while j < limit {
                is_prime[j] = false;
                j += i;
            }
        }
    }

    let primes_count = is_prime.iter().filter(|&&p| p).count() as i32;

    let duration = start.elapsed();

    let process_id = std::process::id();

    // Get memory usage
    let mut sys = System::new_all();
    sys.refresh_all();
    let working_set_mb = if let Some(process) = sys.process(sysinfo::Pid::from_u32(process_id)) {
        process.memory() as f64 / (1024.0 * 1024.0)
    } else {
        0.0
    };

    let result = BenchmarkResult {
        execution_time_ms: duration.as_millis() as i64,
        primes_found: primes_count,
        process_id,
        working_set_mb,
    };

    HttpResponse::Ok().json(result)
}
