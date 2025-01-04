# Clear all variables in the current session
Clear-Variable * -Scope Global -Force -ErrorAction SilentlyContinue

# Ensure the required module is installed
if (-not (Get-Module -Name Indented.Net.IP -ErrorAction SilentlyContinue)) {
    Write-Host "Indented.Net.IP module is not installed. Installing from PowerShell Gallery..."
    Install-Module -Name Indented.Net.IP -Scope CurrentUser -Force
}
Import-Module -Name Indented.Net.IP -ErrorAction Stop
# Example usage
$BaseIPAddress = "10.113.20.0/24"
$IPs = Get-NetworkRange $BaseIPAddress | Select-Object IPAddressToString
#Test-IPRange -IPList $IPs
ForEach ($IP in $IPs) {
    $IPtoTest = $IP.IPAddressToString
    #Write-Output "Testing $IPtoTest...." #Uncommet this line to see the progress
    # Test the connection
    if (Test-NetConnection -ComputerName $IPtoTest -InformationLevel Quiet | Out-Null) {
        Write-Output "$IPtoTest Taken" 
    } else {
        Write-Output "$IPtoTest Free" 
    }
}