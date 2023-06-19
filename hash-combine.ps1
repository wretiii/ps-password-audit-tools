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
}

# Prompt to display all results or results for a specific string
$displayOption = Read-Host "Choose an option:`n1. Display all results`n2. Display results for a specific string"

if ($displayOption -eq "2") {
    $filterString = Read-Host "Enter the string to filter the results"
    $combinedHashes = $combinedHashes | Where-Object { $_.Username -like "*$filterString*" }
}

# Sort the combined hashes by username in alphabetical order
$sortedHashes = $combinedHashes | Sort-Object -Property Username

# Output the results to the terminal and save to a text file
$output = $sortedHashes | ForEach-Object {
    $username = $_.Username
    $password = $_.Password
    foreach ($user in $username) {
        foreach ($pass in $password) {
            "${user}:$pass"
        }
    }
}

# Prompt to save the output to a file
$saveToFile = Read-Host "Do you want to save the output to a file? (Y/N)"

if ($saveToFile -eq "Y" -or $saveToFile -eq "y") {
    # Prompt for the file name
    $fileName = Read-Host "Enter the file name"

    # Save the output to a text file
    $outputFilePath = "$PWD\$fileName.txt"
    $output | Sort-Object | Out-File -FilePath $outputFilePath

    Write-Host "Output saved to $outputFilePath"
}

# Output the results to the terminal
Write-Host "Results:"
$output | Sort-Object
