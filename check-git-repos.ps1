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

    # Fetch all updates from the remote repository
    git fetch --all --quiet

    # Get the current branch name
    $branchName = $(git rev-parse --abbrev-ref HEAD)

    # Get the relationship with the remote branch
    $branchStatus = $(git status -sb)

    # Update progress
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

    # Prepare the branch information for the details
    $details = "Branch: $branchName, Status: $branchStatus"

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

