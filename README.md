# Cidrolver
This tool creates a list of ordered IP addresses from a list of mixed ranges.

#### WHY? 
Useful if you need a list of all the IP addresses included in various ranges or to calculate the total number.

#### USAGE:
```./cidrolver.sh list.txt output.txt```

> **Required argument:** input file name  
> **Optional argument:** output file name

The list can include a mixture of IP/Ranges.
Accepted types/format:
- 10.0.0.1
- 10.0.0.0/24
- 10.0.0.1-255
- 10.0.0.1-10.0.0.255

# ISSUES:
- Currently misses first IP address of ranges like: 10.0.0.1-10.0.0.3 (only prints 10.0.0.2, 10.0.0.3)
