param(
    [string]$repository = "POC.xDB Analytics Extractor", 
    [string]$ref = $null,
    [string]$path = $null,
    [switch]$ignoreUntracked,
    [int]$fetchDepth = 1,
    [switch]$fetchTags,
    [string]$filter = $null,
    [string]$gitServerUrl = "https://github.com/",
    [switch]$reclone
)

# Force update

if ($reclone) {
    # Construct the git clone command
    $gitCloneCommand = "git clone"

    if (-not $path -or $path -eq "") {
        # Check if there's a directory with the name of the repository
        $repoDirectoryName = $repository -split '/' | Select-Object -Last 1
        if (Test-Path $repoDirectoryName -PathType Container) {
            $path = ".\$repoDirectoryName"
        }
    }

    if ($path -ne "" -and (Test-Path $path -PathType Container)) {
        # Remove all content from the directory
        Remove-Item -Path "$path\*" -Recurse -Force
    }
    
    $gitCloneCommand += " $gitServerUrl/$repository $path"

    if ($ref) {
        Write-Host "Cloning the repository with the provided ref: $ref"
        $gitCloneCommand += " --branch=$ref"
    }

    if ($filter) {
        Write-Host "Cloning the repository with the provided filters: $filter" -ForegroundColor Cyan
        $gitCloneCommand += " --filter=$filter"
    }

    # Execute the git clone command
    Invoke-Expression $gitCloneCommand

    Write-Host "Recloned the repository." -ForegroundColor Green
}
else {
    Write-Host "No recloning performed." -ForegroundColor Cyan
}

# Check if $path is set, if not, search for the repository name in the current directory and its
# subdirectories

if (-not $path) {
    $foundPath = Get-ChildItem -Recurse -Filter $repository -Directory | Select-Object -ExpandProperty FullName
    
    if (-not $foundPath) {
        throw "Error: Repository '$repository' not found in current directory or its subdirectories. Consider running the command with the recloning option"
    }

    $path = $foundPath
}

# Navigate to the correct path
Write-Host "Navigating to the project path '$path'" -ForegroundColor Cyan
Set-Location $path

if ($ignoreUntracked -ne $true) {
    # Run git clean -ffdx
    git clean -ffdx

    # Run git reset --hard HEAD
    git reset --hard HEAD

    Write-Host "Git clean and reset completed." -ForegroundColor Blue
}
else {
    Write-Host "No Git clean and reset performed." -ForegroundColor DarkYellow
}

$gitFetchCommand = "git fetch"

if ($fetchDepth -ne 0) {
    Write-Host "Fetch depth is set to $FetchDepth." -ForegroundColor DarkYellow
    $gitFetchCommand += " --depth=$FetchDepth"
}

if ($fetchTags) {
    Write-Host "Fetching tags in a depth of $FetchDepth." -ForegroundColor DarkYellow
    $gitFetchCommand += " --tags"
}

Invoke-Expression $gitFetchCommand

$gitDefaultBranch = git symbolic-ref refs/remotes/origin/HEAD | ForEach-Object { $_ -replace '^refs/remotes/origin/' }

$gitCheckoutCommand = "git checkout origin "

if ($ref -ne '') {
    $gitCheckoutCommand += $ref
}
else {
    $gitCheckoutCommand += $gitDefaultBranch
}

Invoke-Expression $gitCheckoutCommand

# for now
git checkout project-structure