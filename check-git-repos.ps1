# Escape and colour codes for use in virtual terminal escape sequences
$esc = [char]27
$red = '31'
$green = '32'

# Get child folders of the current folder which contain a '.git' folder
Get-ChildItem -Path . -Attributes Directory+Hidden -Recurse -Filter '.git' | 
ForEach-Object { 
    # Assume the parent folder of this .git folder is the working copy
    $workingCopy = $_.Parent
    $repositoryName = $workingCopy.Name

    # Change the working folder to the working copy
    Push-Location $workingCopy.FullName

    # from chatgpt - update stuff first
    git fetch --all --quiet

    # Update progress, as using -AutoSize on Format-Table
    # stops anything being written to the terminal until 
    # *all* processing is finished
    Write-Progress `
        -Activity 'Check For Local Changes' `
        -Status 'Checking:' `
        -CurrentOperation $repositoryName

    # Get a list of untracked/uncommitted changes
    [Array]$gitStatus = $(git status --porcelain) | 
        ForEach-Object { $_.Trim() }

    # Status includes VT escape sequences for coloured text
    $status = ($gitStatus) `
        ? "$esc[$($red)mCHECK$esc[0m" `
        : "$esc[$($green)mOK$esc[0m"

    # For some reason, the git status --porcelain output returns 
    # two '?' chars for untracked changes, when all other statuses 
    # are one character... this just cleans it up so that it's 
    # nicer to scan visually in the terminal
    $details = ($gitStatus -replace '\?\?', '?' | Out-String).TrimEnd()

    # Change back to the original directory
    Pop-Location

    # Return a simple 'row' object containing all the info
    [PSCustomObject]@{ 
        Status = $status
        'Working Copy' = $repositoryName
        Details = $details
    }
} |
Format-Table -Wrap -AutoSize
