$FormatEnumerationLimit = -1

# Prompt for the file path of the NTLM hashes file
$ntlmFile = Read-Host "Enter the file path for the NTLM hashes file"

# Prompt for the file path of the Hashcat pot file of cracked hashes
$crackedFile = Read-Host "Enter the file path for the Hashcat pot file of cracked hashes"

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

# Sort the combined hashes by the count of accounts using the same password in descending order
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
$results = $sortedHashes | ForEach-Object {
    $password = $_.Key
    $usernames = $_.Value | Select-Object -ExpandProperty Username
    $count = $usernames.Count

    [PSCustomObject]@{
        Password = $password
        Count = $count
        Usernames = $usernames -join ', '
    }
}

# Sort the results by the count of accounts in descending order
$results = $results | Sort-Object -Property Count -Descending

# Output the results to the terminal
Write-Host "Results:"

$results | ForEach-Object {
    $password = $_.Password
    $count = $_.Count
    $usernames = $_.Usernames

    Write-Host "$password ($count) : $usernames"
}

# Prompt to save the output to a text file
$saveOption = Read-Host "Do you want to save the results to a text file? (Y/N)"
if ($saveOption -eq "Y") {
    $fileName = Read-Host "Enter the file name to save the results"
    $fileName += ".txt"
    $results | ForEach-Object {
        $line = "$($_.Password) ($($_.Count)) : $($_.Usernames)"
        Add-Content -Path $fileName -Value $line
    }
}
