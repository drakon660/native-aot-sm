# Task Manager to CIM Property Mapping

## Task Manager Columns and Their CIM Equivalents

### Main Memory Columns

| Task Manager Column | CIM Property | Description |
|---------------------|--------------|-------------|
| **Memory** | `PrivateBytes` | Private committed memory - This is what you see by default in Task Manager |
| **Active private working set** | `WorkingSetPrivate` | Private portion of physical RAM (Windows 10/11) |
| **Working set (memory)** | `WorkingSet` | Total physical RAM used (includes shared memory) |
| **Peak working set** | `WorkingSetPeak` | Maximum physical RAM used since process start |
| **Commit size** | `PageFileBytes` | Total committed memory (RAM + page file) |
| **Paged pool** | `PoolPagedBytes` | Kernel paged pool memory |
| **NP pool** | `PoolNonpagedBytes` | Kernel non-paged pool memory |

### Virtual Memory Columns

| Task Manager Column | CIM Property | Description |
|---------------------|--------------|-------------|
| **Commit size** | `PageFileBytes` | Virtual memory committed |
| **Virtual memory** | `VirtualBytes` | Total virtual address space reserved |
| **Peak virtual memory** | `VirtualBytesPeak` | Maximum virtual memory used |

## What You See in Different Task Manager Views

### Details Tab (Default View)
The **"Memory"** column shows: **`PrivateBytes`**
- This is private committed memory
- Most stable metric for comparison
- What we use in compare-performance.ps1

### Details Tab (Add Columns)
When you add more columns, you can see:
- **Active private working set**: `WorkingSetPrivate`
- **Working set (memory)**: `WorkingSet`
- **Peak working set**: `WorkingSetPeak`
- **Commit size**: `PageFileBytes`

### Performance Tab
Shows multiple metrics including:
- **Memory**: `WorkingSet` (total physical RAM)
- **Memory (Private)**: `PrivateBytes`

## Key Differences

### PrivateBytes vs WorkingSet
- **PrivateBytes** (`Memory` column): Memory exclusively allocated to this process
  - More stable, doesn't fluctuate as much
  - Good for comparing memory footprint between processes
  - This is what Task Manager shows by default

- **WorkingSet**: Total physical RAM currently in use
  - Includes shared DLLs and memory-mapped files
  - Can fluctuate due to Windows memory management
  - Higher than PrivateBytes

### WorkingSetPrivate vs PrivateBytes
- **WorkingSetPrivate**: Private memory currently in physical RAM
  - Subset of WorkingSet (excludes shared memory)
  - Most accurate for "real" memory usage
  - Available in Windows 10/11

- **PrivateBytes**: Private memory committed (RAM + reserved page file)
  - Can be higher than WorkingSetPrivate if some is paged to disk
  - What Task Manager shows as "Memory"

## Example from Task Manager

```
Process Name        Memory      Working Set    Active private working set
----------------    --------    -----------    --------------------------
AotMinimalApi.exe   45.2 MB     52.3 MB       44.8 MB
StandardMinimalApi  65.8 MB     78.1 MB       64.2 MB
```

Maps to CIM:
- **Memory** = `PrivateBytes`
- **Working Set** = `WorkingSet`
- **Active private working set** = `WorkingSetPrivate`

## Which One to Use?

**For Performance Comparisons**: Use **`PrivateBytes`** (Task Manager "Memory")
- Most stable
- Standard metric everyone uses
- What we use in compare-performance.ps1

**For Real-Time Monitoring**: Use **`WorkingSetPrivate`**
- Most accurate for actual RAM usage
- Best for understanding real memory pressure

**For System Analysis**: Use **`WorkingSet`**
- Shows total physical RAM impact
- Useful for system-wide memory analysis
