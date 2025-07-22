# Get-AtomicTestInfo.ps1
# Script to display and optionally execute hardcoded Atomic Red Team tests with a banner

# Display ASCII art banner
Write-Output @"
  ______   _______  ________  __    __    __   
 /      \ |       \|        \|  \  |  \ _/  \  
|  $$$$$$\| $$$$$$$\\$$$$$$$$| $$  | $$|   $$  
| $$__| $$| $$__/ $$  | $$   | $$__| $$ \$$$$  
| $$    $$| $$    $$  | $$   | $$    $$  | $$  
| $$$$$$$$| $$$$$$$   | $$    \$$$$$$$$  | $$  
| $$  | $$| $$        | $$         | $$ _| $$_ 
| $$  | $$| $$        | $$         | $$|   $$ \
 \$$   \$$ \$$         \$$          \$$ \$$$$$$
                                               
   (G0096)
   Author: 05t3
"@

# Hardcoded list of Atomic test IDs in specified order
$TestIDs = @(
    # Execution
    "T1047-1",
    "T1047-2",
    "T1047-3",
    "T1047-4",
    "T1047-5",
    # Persistence & Defense Evasion
    "T1197-3",
    "T1546.008-5",
    "T1546.008-7",
    "T1546.008-8",
    "T1136.001-8",
    "T1136.001-4",
    # Discovery
    "T1087.001-9",
    "T1087.001-10",
    "T1087.002-17",
    "T1046-10",
    "T1135-5",
    "T1018-5",
    "T1033-1",
    # Credential Access
    "T1003.001-10",
    "T1003.001-13",
    "T1003.003-7"
)

# Import the Invoke-AtomicRedTeam module
$modulePath = "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1"
if (-not (Test-Path $modulePath)) {
    Write-Warning "Invoke-AtomicRedTeam module not found at $modulePath"
    exit 1
}
Import-Module $modulePath -Force

# Create a temporary file to capture output
$tempFile = [System.IO.Path]::GetTempFileName()

# Initialize an array to store the formatted output
$outputLines = @()

# Display test IDs and names
foreach ($testID in $TestIDs) {
    # Split test ID into technique and test number (e.g., T1087.001-9 -> T1087.001, 9)
    if ($testID -match "^(T\d{4}(?:\.\d{3})?)-(\d+)$") {
        $techniqueID = $matches[1]
        $testNumber = $matches[2]
        try {
            # Run Invoke-AtomicTest and redirect output to a temporary file
            Invoke-AtomicTest $techniqueID -TestNumbers $testNumber -ShowDetailsBrief -ErrorAction Stop *> $tempFile
            # Read the file and filter out unwanted lines
            $output = Get-Content $tempFile -Raw
            $testLine = $output -split "`n" | Where-Object { $_ -match "^\s*$testID\s+(.+)$" -and $_ -notmatch "PathToAtomicsFolder" } | Select-Object -First 1
            if ($testLine -and $Matches[1]) {
                $testName = $Matches[1].Trim()
                $outputLines += "|$testID|`t$testName|"
            } else {
                $outputLines += "|$testID|`tTest name not found|"
            }
        } catch {
            $outputLines += "|$testID|`tError executing Invoke-AtomicTest: $($_.Exception.Message)|"
        }
    } else {
        $outputLines += "|$testID|`tInvalid test ID format|"
    }
}

# Output the table
$outputLines | ForEach-Object { Write-Output $_ }

# Clean up the temporary file
Remove-Item $tempFile -Force

# Prompt user to execute tests on the same line
Write-Host "`nDo you want to execute the listed Atomic tests? (Y/N) " -NoNewLine
$response = Read-Host
if ($response -eq "Y" -or $response -eq "y") {
    foreach ($testID in $TestIDs) {
        if ($testID -match "^(T\d{4}(?:\.\d{3})?)-(\d+)$") {
            $techniqueID = $matches[1]
            $testNumber = $matches[2]
            try {
                Write-Output "`nExecuting test $testID..."
                Invoke-AtomicTest $techniqueID -TestNumbers $testNumber -ErrorAction Stop
            } catch {
                Write-Output "Error executing test $testID`: $($_.Exception.Message)"
            }
        } else {
            Write-Output "Skipping test $testID`: Invalid test ID format"
        }
    }
} else {
    Write-Output "Execution cancelled by user."
}