use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BenchmarkResult {
    #[serde(rename = "executionTimeMs")]
    pub execution_time_ms: i64,
    #[serde(rename = "primesFound")]
    pub primes_found: i32,
    #[serde(rename = "processId")]
    pub process_id: u32,
    #[serde(rename = "workingSetMB")]
    pub working_set_mb: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: i32,
    #[serde(rename = "firstName")]
    pub first_name: String,
    #[serde(rename = "lastName")]
    pub last_name: String,
    pub email: String,
    #[serde(rename = "phoneNumber")]
    pub phone_number: String,
    #[serde(rename = "dateOfBirth")]
    pub date_of_birth: String,
    pub address: Address,
    pub company: Company,
    pub preferences: UserPreferences,
    pub metadata: HashMap<String, String>,
    pub tags: Vec<String>,
    #[serde(rename = "isActive")]
    pub is_active: bool,
    #[serde(rename = "createdAt")]
    pub created_at: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Address {
    pub street: String,
    pub city: String,
    pub state: String,
    #[serde(rename = "zipCode")]
    pub zip_code: String,
    pub country: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Company {
    pub name: String,
    pub department: String,
    pub position: String,
    pub salary: f64,
    #[serde(rename = "startDate")]
    pub start_date: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserPreferences {
    pub theme: String,
    pub language: String,
    #[serde(rename = "notificationsEnabled")]
    pub notifications_enabled: bool,
    pub newsletter: bool,
    #[serde(rename = "twoFactorEnabled")]
    pub two_factor_enabled: bool,
}
