package com.example.springbootgraalvm.model;

public class BenchmarkResult {
    private long executionTimeMs;
    private int primesFound;
    private long processId;
    private double workingSetMB;

    public long getExecutionTimeMs() { return executionTimeMs; }
    public void setExecutionTimeMs(long executionTimeMs) { this.executionTimeMs = executionTimeMs; }

    public int getPrimesFound() { return primesFound; }
    public void setPrimesFound(int primesFound) { this.primesFound = primesFound; }

    public long getProcessId() { return processId; }
    public void setProcessId(long processId) { this.processId = processId; }

    public double getWorkingSetMB() { return workingSetMB; }
    public void setWorkingSetMB(double workingSetMB) { this.workingSetMB = workingSetMB; }
}
