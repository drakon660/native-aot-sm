# Memory Properties in PowerShell Get-Process

## Main Memory Properties

### 1. **WorkingSet64** (Int64)
- **What it is**: Total physical memory (RAM) currently used by the process
- **Task Manager equivalent**: "Memory (Active Private Working Set)" or "Working Set (Memory)"
- **When to use**: General memory usage, but can fluctuate due to OS paging
- **Note**: Includes both private and shared memory

### 2. **PrivateMemorySize64** (Int64)
- **What it is**: Memory allocated exclusively to this process (private bytes)
- **Task Manager equivalent**: "Memory" column in Windows 10/11 Task Manager
- **When to use**: Most accurate for comparing process memory usage
- **Note**: This is what we use in compare-performance.ps1 - most stable metric

### 3. **VirtualMemorySize64** (Int64)
- **What it is**: Total virtual address space reserved by the process
- **Task Manager equivalent**: "Commit Size"
- **When to use**: Understanding total memory commitment (physical + page file)
- **Note**: Can be much larger than physical memory used

### 4. **PagedMemorySize64** (Int64)
- **What it is**: Memory that can be paged to disk (virtual memory)
- **Task Manager equivalent**: Part of "Commit Size"
- **When to use**: Understanding paging behavior
- **Note**: Most process memory is paged

### 5. **NonpagedSystemMemorySize64** (Int64)
- **What it is**: System memory that must stay in RAM (cannot be paged)
- **Task Manager equivalent**: Part of "Non-paged pool"
- **When to use**: Driver/kernel memory analysis
- **Note**: Usually very small for user-mode applications

### 6. **PeakWorkingSet64** (Int64)
- **What it is**: Maximum physical memory used since process start
- **Task Manager equivalent**: "Peak Working Set"
- **When to use**: Finding peak memory usage over time
- **Note**: Historical data, not current usage

### 7. **PeakVirtualMemorySize64** (Int64)
- **What it is**: Maximum virtual memory used since process start
- **Task Manager equivalent**: "Peak Commit Size"
- **When to use**: Finding peak virtual memory commitment
- **Note**: Historical data

### 8. **PeakPagedMemorySize64** (Int64)
- **What it is**: Maximum paged memory used since process start
- **When to use**: Historical paging analysis
- **Note**: Historical data

## Quick Reference

```powershell
$process = Get-Process -Name "YourApp"

# Memory in MB
[math]::Round($process.PrivateMemorySize64 / 1MB, 2)     # Private (most stable)
[math]::Round($process.WorkingSet64 / 1MB, 2)             # Working Set (in RAM)
[math]::Round($process.VirtualMemorySize64 / 1MB, 2)     # Virtual memory
[math]::Round($process.PagedMemorySize64 / 1MB, 2)       # Pageable memory
```

## Recommendations

**For Performance Comparisons** (like our scripts):
- Use **PrivateMemorySize64** - Most stable and matches Task Manager's "Memory" column

**For Real-Time Monitoring**:
- Use **WorkingSet64** - Shows actual RAM usage right now

**For Peak Usage Analysis**:
- Use **PeakWorkingSet64** or **PeakVirtualMemorySize64**

## Task Manager Column Mapping

| Task Manager Column | PowerShell Property |
|---------------------|---------------------|
| Memory | PrivateMemorySize64 |
| Active Private Working Set | WorkingSet64 |
| Commit Size | VirtualMemorySize64 |
| Peak Working Set | PeakWorkingSet64 |
