package com.example.springbootgraalvm.controller;

import com.example.springbootgraalvm.model.*;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@RestController
public class ApiController {

    @GetMapping("/users")
    public List<User> getUsers() {
        String[] firstNames = {"James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Barbara", "David", "Elizabeth", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Christopher", "Karen"};
        String[] lastNames = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin"};
        String[] cities = {"New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville", "Fort Worth", "Columbus", "Indianapolis", "Charlotte", "San Francisco", "Seattle", "Denver", "Washington"};
        String[] streets = {"Main Street", "Oak Avenue", "Maple Drive", "Cedar Lane", "Pine Road", "Elm Street", "Washington Boulevard", "Park Avenue", "Lake Drive", "Hill Street", "River Road", "Forest Lane", "Spring Street", "Valley Road", "Mountain View", "Sunset Boulevard", "Broadway", "First Avenue", "Second Street", "Third Avenue"};
        String[] companies = {"TechCorp", "GlobalSystems", "DataWorks", "CloudNine", "InnovateLabs", "FutureSync", "AlphaTech", "BetaSoft", "GammaIndustries", "DeltaSolutions", "EpsilonGroup", "ZetaDigital", "EtaTechnologies", "ThetaVentures", "IotaEnterprises"};
        String[] departments = {"Engineering", "Sales", "Marketing", "Human Resources", "Finance", "Operations", "Customer Support", "Product Management", "Research and Development", "Quality Assurance", "Legal", "IT Support", "Business Development", "Accounting", "Administration"};
        String[] positions = {"Software Engineer", "Senior Developer", "Product Manager", "Sales Representative", "Marketing Specialist", "HR Manager", "Financial Analyst", "Operations Manager", "Support Specialist", "QA Engineer", "Team Lead", "Director", "Vice President", "Consultant", "Coordinator"};
        String[] states = {"CA", "NY", "TX", "FL", "PA", "IL", "OH", "GA", "NC", "MI", "NJ", "VA", "WA", "AZ", "MA", "TN", "IN", "MO", "MD", "WI"};
        String[] tags = {"VIP", "Premium", "Enterprise", "Verified", "Active", "Beta", "EarlyAdopter", "Ambassador", "Partner", "Influencer", "Champion", "Leader", "Expert", "Mentor", "Contributor"};

        List<User> users = new ArrayList<>();
        LocalDateTime baseDate = LocalDateTime.of(2020, 1, 1, 0, 0);

        for (int i = 1; i <= 10000; i++) {
            int fnIndex = (i * 7) % firstNames.length;
            int lnIndex = (i * 11) % lastNames.length;
            int cityIndex = (i * 13) % cities.length;
            int streetIndex = (i * 17) % streets.length;
            int stateIndex = (i * 19) % states.length;
            int companyIndex = (i * 23) % companies.length;
            int deptIndex = (i * 29) % departments.length;
            int posIndex = (i * 31) % positions.length;

            String firstName = firstNames[fnIndex];
            String lastName = lastNames[lnIndex];
            String email = String.format("%s.%s%d@example.com", firstName.toLowerCase(), lastName.toLowerCase(), i);
            int age = 25 + (i % 50);
            int yearsAtCompany = 1 + (i % 15);

            User user = new User();
            user.setId(i);
            user.setFirstName(firstName);
            user.setLastName(lastName);
            user.setEmail(email);
            user.setPhoneNumber(String.format("+1-%03d-%03d-%04d",
                200 + (i % 800),
                100 + (i % 900),
                1000 + (i % 9000)));
            user.setDateOfBirth(baseDate.minusYears(age).plusDays(i % 365));

            Address address = new Address();
            address.setStreet(String.format("%d %s", 100 + (i % 9900), streets[streetIndex]));
            address.setCity(cities[cityIndex]);
            address.setState(states[stateIndex]);
            address.setZipCode(String.format("%05d", 10000 + (i % 89999)));
            address.setCountry("USA");
            user.setAddress(address);

            Company company = new Company();
            company.setName(companies[companyIndex]);
            company.setDepartment(departments[deptIndex]);
            company.setPosition(positions[posIndex]);
            company.setSalary(BigDecimal.valueOf(40000 + (i % 160000)));
            company.setStartDate(baseDate.plusYears(yearsAtCompany).plusDays(i % 365));
            user.setCompany(company);

            UserPreferences preferences = new UserPreferences();
            preferences.setTheme(i % 2 == 0 ? "Dark" : "Light");
            preferences.setLanguage((i % 3) == 0 ? "en" : (i % 3) == 1 ? "es" : "fr");
            preferences.setNotificationsEnabled(i % 3 != 0);
            preferences.setNewsletter(i % 4 != 0);
            preferences.setTwoFactorEnabled(i % 5 == 0);
            user.setPreferences(preferences);

            Map<String, String> metadata = new HashMap<>();
            metadata.put("LastLogin", baseDate.plusDays(i % 730).format(DateTimeFormatter.ISO_DATE_TIME));
            metadata.put("AccountStatus", i % 10 == 0 ? "Inactive" : "Active");
            metadata.put("VerificationLevel", String.valueOf((i % 3) + 1));
            metadata.put("ReferralCode", String.format("REF%06d", i));
            metadata.put("CustomerSince", baseDate.minusMonths(i % 60).format(DateTimeFormatter.ISO_DATE_TIME));
            user.setMetadata(metadata);

            final int currentIndex = i;
            List<String> userTags = IntStream.range(0, 3 + (i % 6))
                .mapToObj(j -> tags[(currentIndex + j) % tags.length])
                .distinct()
                .collect(Collectors.toList());
            user.setTags(userTags);

            user.setActive(i % 10 != 0);
            user.setCreatedAt(baseDate.plusDays(i % 1825));
            user.setUpdatedAt(baseDate.plusDays(1825 + (i % 365)));

            users.add(user);
        }

        return users;
    }

    @GetMapping("/benchmark")
    public BenchmarkResult benchmark() {
        long startTime = System.currentTimeMillis();

        // CPU-intensive task: Calculate prime numbers
        List<Long> primes = new ArrayList<>();
        for (int i = 2; i < 1000000; i++) {
            boolean isPrime = true;
            for (int j = 2; j * j <= i; j++) {
                if (i % j == 0) {
                    isPrime = false;
                    break;
                }
            }
            if (isPrime) {
                primes.add((long) i);
            }
        }

        long executionTime = System.currentTimeMillis() - startTime;

        // Get process working set memory (equivalent to C# Environment.WorkingSet)
        // Using Runtime for simpler memory calculation that works in native image
        Runtime runtime = Runtime.getRuntime();
        double workingSetMB = (runtime.totalMemory() - runtime.freeMemory()) / (1024.0 * 1024.0);

        BenchmarkResult result = new BenchmarkResult();
        result.setExecutionTimeMs(executionTime);
        result.setPrimesFound(primes.size());
        result.setProcessId(ProcessHandle.current().pid());
        result.setWorkingSetMB(workingSetMB);

        return result;
    }
}
