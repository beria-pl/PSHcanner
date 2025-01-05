param (
    [Parameter(Mandatory=$true)]
    [string]$BaseIPAddress
)

# Clear all variables in the current session
Clear-Variable * -Scope Global -Force -ErrorAction SilentlyContinue | Out-Null

# Ensure the required module is installed
if (-not (Get-Module -Name Indented.Net.IP -ErrorAction SilentlyContinue)) {
    Write-Host "Indented.Net.IP module is not installed. Installing from PowerShell Gallery..."
    Install-Module -Name Indented.Net.IP -Scope CurrentUser -Force
}
Import-Module -Name Indented.Net.IP -ErrorAction Stop

# Example usage
$IPs = Get-NetworkRange $BaseIPAddress | Select-Object IPAddressToString

# Create jobs for parallel execution
$jobs = @()
ForEach ($IP in $IPs) {
    $IPtoTest = $IP.IPAddressToString
    $jobs += Start-Job -ScriptBlock {
        param ($IPtoTest)
        if (Test-Connection -ComputerName $IPtoTest -Count 1 -Quiet) {
            [PSCustomObject]@{ IP = $IPtoTest; Status = "Taken" }
        } else {
            [PSCustomObject]@{ IP = $IPtoTest; Status = "Free" }
        }
    } -ArgumentList $IPtoTest
}

# Wait for all jobs to complete
$jobs | ForEach-Object { $_ | Wait-Job }

# Collect and sort results
$results = $jobs | ForEach-Object { Receive-Job -Job $_ }

function Convert-IPToNumber {
    param ($IP)
    [uint32]$number = 0
    $IP.Split('.') | ForEach-Object { $number = ($number -shl 8) + [uint32]$_ }
    return $number
}

# Sort results by IP address
$sortedResults = $results | Sort-Object { Convert-IPToNumber $_.IP }

# Output results with coloring
$sortedResults | ForEach-Object {
    if ($_.Status -eq "Free") {
        Write-Host "$($_.IP) $($_.Status)" -ForegroundColor Green
    } else {
        Write-Host "$($_.IP) $($_.Status)" -ForegroundColor Yellow
    }
}

# Clean up jobs
$jobs | ForEach-Object { Remove-Job -Job $_ }