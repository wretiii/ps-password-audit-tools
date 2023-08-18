# ps-password-audit-tools
Powershell scripts to aid with password auditing.

Example hash input: Administrator:500:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::

Both scripts have the option to list the full output or search specific strings, eg 'admin', as well as the option to save the output to a text file.

hash-combine.ps1 - Combine the file of raw NTLM hashes with the Hashcat potfile to display user:pass in the terminal. \n
password-reuse.ps1 - Combine the file of raw NTLM hashes with the Hashcat potfile to display in descending order the password, the number of times that password is used by an account, and the accounts using the password.
