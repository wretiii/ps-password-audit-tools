Add-Type -AssemblyName System.Windows.Forms

# Prompt for the file path of the NTLM hashes file
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Select NTLM File"
$openFileDialog.ShowDialog() | Out-Null

$ntlmFile = $openFileDialog.FileName

Write-Output "NTLM file: $ntlmFile"

# Read the NTLM hashes from the file into a hash table for faster lookup
$ntlmHashes = Get-Content $ntlmFile | ForEach-Object {
    $fields = $_ -split ":"
    $username = $fields[0]
    $hash = $fields[3]
    [PSCustomObject]@{
        Hash = $hash
        Username = $username
    }
} | Group-Object -Property Hash -AsHashTable -AsString

# Sort the NTLM hashes by the number of accounts using the same hash
$sortedHashes = $ntlmHashes.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending

# Output the matched usernames for each hash
foreach ($hashEntry in $sortedHashes) {
    $hash = $hashEntry.Key
    $usernames = $hashEntry.Value | Select-Object -ExpandProperty Username
    $count = $usernames.Count

    if ($count -gt 1) { # Only display hashes used by more than one account
        Write-Host "$hash ($count) : $($usernames -join ', ')"
    }
}

# Prompt to save the output to a CSV file
$saveOption = Read-Host "Do you want to save the results to a CSV file? (Y/N)"
if ($saveOption -eq "Y") {
    $fileName = Read-Host "Enter the file name to save the results"
    $fileName += ".csv"

    $csvContent = $sortedHashes | Where-Object { $_.Value.Count -gt 1 } | ForEach-Object {
        $hash = $_.Key
        $usernames = $_.Value | Select-Object -ExpandProperty Username
        $count = $usernames.Count

        [PSCustomObject]@{
            Hash = $hash
            Count = $count
            Usernames = $usernames -join ', '
        }
    }

    $csvContent | Export-Csv -Path $fileName -NoTypeInformation

    Write-Host "Results saved to $fileName"
} else {
    Write-Host "Results not saved."
}
