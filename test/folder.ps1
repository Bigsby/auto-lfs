vboxmanage list systemproperties | 
    Where-Object {$_ -Match "^Default machine folder:\s+(.*)$"} |
    ForEach-Object {Write-Host $_.Groups.Count}
    # Select-Object -Index 0 -OutVariable Groups |
    # Select-Object -Index 1 -OutVariable Value

