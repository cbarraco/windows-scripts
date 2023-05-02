<#
    .SYNOPSIS
        Clones all GitHub repositories of a given user.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $User,
    [Parameter(Mandatory = $false)]
    [string] $Directory = "$env:USERPROFILE\Development",
    [Parameter(Mandatory = $false)]
    [switch] $HTTP = $false
)
    
begin {
        
}
    
process {
    $repos = Invoke-RestMethod -Uri "https://api.github.com/users/$User/repos?per_page=1000"
    $repos | ForEach-Object {
        $repo = $_
        $repoName = $repo.name
        $repoUrl = $HTTP ? $repo.clone_url : $repo.ssh_url
        $repoPath = "$Directory\$repoName"
        if (!(Test-Path $repoPath)) {
            git clone "$repoUrl" "$repoPath"
        }
    }
}
    
end {
        
}