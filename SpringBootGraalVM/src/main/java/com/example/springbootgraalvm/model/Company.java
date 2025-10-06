package com.example.springbootgraalvm.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Company {
    private String name = "";
    private String department = "";
    private String position = "";
    private BigDecimal salary = BigDecimal.ZERO;
    private LocalDateTime startDate;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getPosition() { return position; }
    public void setPosition(String position) { this.position = position; }

    public BigDecimal getSalary() { return salary; }
    public void setSalary(BigDecimal salary) { this.salary = salary; }

    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }
}
