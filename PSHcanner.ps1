<#
.SYNOPSIS
    A PowerShell script to scan a subnet for active and inactive IP addresses.

.DESCRIPTION
    PSHcanner is a PowerShell tool that scans a given subnet in CIDR notation (e.g., 192.168.1.0/24) 
    to identify active (in use) and inactive (free) IP addresses. It uses parallel processing to 
    speed up the scanning process and outputs the results for each IP.

.PARAMETER SubnetRange
    The subnet to scan, specified in CIDR notation. For example:
    - 192.168.1.0/24 for a Class C subnet with 254 possible IPs.
    - 10.0.0.0/16 for a Class B subnet with 65,534 possible IPs.

.EXAMPLE
    PS C:\> .\PSHcanner.ps1 -SubnetRange 192.168.1.0/24

    Scans the 192.168.1.0/24 subnet and outputs which IPs are active or free.

.EXAMPLE
    PS C:\> .\PSHcanner.ps1 -SubnetRange 10.0.0.0/16

    Scans the 10.0.0.0/16 subnet, a larger Class B range, for active or free IPs.

.NOTES
    Author  : Your Name
    Version : 1.0
    Created : 2025-01-04
    Requires: PowerShell 7.0 or later for parallel processing.

#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter a subnet in CIDR notation (e.g., 192.168.1.0/24).")]
    [string]$SubnetRange
)

function Get-IPRange {
    <#
    .SYNOPSIS
        Generates a list of all usable IPs in the specified CIDR range.

    .DESCRIPTION
        This function calculates all IP addresses in a given subnet (CIDR format)
        by deriving the network size and iterating over all possible host IPs.

    .PARAMETER SubnetRange
        The subnet in CIDR notation (e.g., 192.168.1.0/24).

    .OUTPUTS
        System.Net.IPAddress
        Outputs all usable IP addresses in the subnet range.

    .EXAMPLE
        PS C:\> Get-IPRange -SubnetRange 192.168.1.0/24
    #>
    param (
        [string]$SubnetRange
    )

    # Extract the base address and CIDR
    $BaseAddress, $CIDR = $SubnetRange -split "/"
    $MaskBits = [int]$CIDR

    # Convert base address to binary
    $BaseAddressBinary = [BitConverter]::ToUInt32([IPAddress]::Parse($BaseAddress).GetAddressBytes(), 0)

    # Calculate the number of usable hosts
    $HostBits = 32 - $MaskBits
    $SubnetSize = [math]::Pow(2, $HostBits) - 2  # Exclude network and broadcast

    # Generate usable IPs
    for ($i = 1; $i -le $SubnetSize; $i++) {
        $CurrentBinary = $BaseAddressBinary + $i
        [IPAddress]::new([BitConverter]::GetBytes([BitConverter]::IsLittleEndian ? [System.BitConverter]::ToUInt32([BitConverter]::GetBytes($CurrentBinary)[0..3]),0)))
    }
}

# Validate input
if (-not $SubnetRange) {
    Write-Error "Please provide a valid subnet range in CIDR notation, e.g., 192.168.1.0/24"
    exit
}

# Generate IP range
$IPs = Get-IPRange -SubnetRange $SubnetRange

# Scan IPs in parallel
$IPs | ForEach-Object -Parallel {
    param($IPAddress)
    if (Test-Connection -ComputerName $IPAddress -Count 2 -Quiet) {
        "$IPAddress is taken"
    } else {
        "$IPAddress is free"
    }
} -ThrottleLimit 16
