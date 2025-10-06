package com.example.springbootgraalvm.model;

public class BenchmarkResult {
    private int primesFound;
    private long processId;
   
    public int getPrimesFound() { return primesFound; }
    public void setPrimesFound(int primesFound) { this.primesFound = primesFound; }

    public long getProcessId() { return processId; }
    public void setProcessId(long processId) { this.processId = processId; }
}
