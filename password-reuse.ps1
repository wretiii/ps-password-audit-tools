Add-Type -AssemblyName System.Windows.Forms

# Prompt for the file path of the NTLM hashes file
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Select NTLM File"
$openFileDialog.ShowDialog() | Out-Null

$ntlmFile = $openFileDialog.FileName

# Prompt for the file path of the Hashcat pot file of cracked hashes
$openFileDialog.Title = "Select Cracked File"
$openFileDialog.ShowDialog() | Out-Null

$crackedFile = $openFileDialog.FileName

Write-Output "NTLM file: $ntlmFile"
Write-Output "Cracked file: $crackedFile"

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

# Process the cracked hashes file and match the passwords to the user accounts
$combinedHashes = Get-Content $crackedFile | ForEach-Object {
    $fields = $_ -split ":"
    $hash = $fields[0]
    $password = $fields[1]
    if ($ntlmHashes.ContainsKey($hash)) {
        $username = $ntlmHashes[$hash].Username
        [PSCustomObject]@{
            Password = $password
            Username = $username
        }
    }
} | Group-Object -Property Password -AsHashTable -AsString

# Sort the combined hashes by the number of accounts using the same password
$sortedHashes = $combinedHashes.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending

# Prompt to display all results or results for a specified string
$displayOption = Read-Host "Choose an option:`n1. Display all results`n2. Display results for a specific string"

if ($displayOption -eq "1") {
    $results = $sortedHashes
}
elseif ($displayOption -eq "2") {
    $filterString = Read-Host "Enter the string to filter the results"
    $results = $sortedHashes | Where-Object { $_.Key -like "*$filterString*" }
}
else {
    Write-Host "Invalid option selected. Displaying all results."
    $results = $sortedHashes
}

# Output the matched usernames for each password
$adminResults = @()
$resultText = ""

foreach ($hashEntry in $results) {
    $password = $hashEntry.Key
    $usernames = $hashEntry.Value | Select-Object -ExpandProperty Username
    $count = $usernames.Count

    if ($usernames -like "*admin*") {
        $adminResults += "$password ($count) : $($usernames -join ', ')"
    } else {
        $resultText += "$password ($count) : $($usernames -join ', ')" + "`n"
    }
}

# Output the results to the terminal
Write-Host "Results:"
if ($adminResults.Count -gt 0) {
    $adminResults | ForEach-Object {
        Write-Host $_
    }
}

if ($resultText.Length -gt 0) {
    Write-Host $resultText
}

# Prompt to save the output to a CSV file
$saveOption = Read-Host "Do you want to save the results to a CSV file? (Y/N)"
if ($saveOption -eq "Y") {
    $fileName = Read-Host "Enter the file name to save the results"
    $fileName += ".csv"

    $csvContent = $results | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
        $password = $_.Key
        $usernames = $_.Value | Select-Object -ExpandProperty Username
        $count = $usernames.Count

        [PSCustomObject]@{
            Password = $password
            Count = $count
            Usernames = $usernames -join ', '
        }
    }

    $csvContent | Sort-Object Count -Descending | Export-Csv -Path $fileName -NoTypeInformation

    # Output the results to the terminal again
    Write-Host "Results saved to $fileName"
} else {
    Write-Host "Results not saved."
}
