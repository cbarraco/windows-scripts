<#
    .SYNOPSIS
        Moves music files into a folder structure based on the metadata of the files.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $Directory,
    [Parameter(Mandatory = $false)]
    [switch] $ActuallyMove,
    [Parameter(Mandatory = $false)]
    [switch] $ActuallyDelete
)

begin {
    if (!$Directory) {
        $Directory = (Get-Location).Path
    }
    else {
        if (!(Test-Path $Directory)) {
            throw "Directory '$Directory' does not exist."
        }
    }
}

process {
    function ConvertTo-FileName([string] $FileName) {
        $fileName = $FileName
        $fileName = $fileName.Replace(":", " -")
        $fileName = $fileName.Replace("/", "+")
        $fileName = $fileName.Replace("\", "+")
        $fileName = $fileName.Replace("?", "")
        $fileName = $fileName.Replace("*", "")
        $fileName = $fileName.Replace("<", "")
        $fileName = $fileName.Replace(">", "")
        $fileName = $fileName.Replace("|", "")
        $fileName = $fileName.Replace("""", "")
        return $fileName
    }

    $shell = New-Object -ComObject Shell.Application
    # find all mp3 and all flac files in the directory
    Write-Host "Searching for music files in: $Directory"
    $musicFiles = Get-ChildItem -Filter *.mp3 -Path $Directory -Recurse
    # $musicFiles += Get-ChildItem -Filter *.flac -Path $Directory -Recurse
    Write-Host "Found $($musicFiles.Count) music files."

    $fileMetadata = @{}
    foreach ($musicFile in $musicFiles) {
        $folder = $shell.Namespace($musicFile.DirectoryName)
        $item = $folder.ParseName($musicFile.Name)
        $fileMetadata[$musicFile.FullName] = @{}
        $properties = @(
            13 # Contributing artists
            14 # Album
            # 15 # Year
            21 # Title
            26 # # - track number
            249 # Part of set - best guess for disc number
        )
        foreach ($property in $properties) {
            $name = $folder.GetDetailsOf($folder.Items, $property)
            $value = $folder.GetDetailsOf($item, $property)
            # Write-Host "$property. $name = $value"
            $fileMetadata[$musicFile.FullName][$name] = $value
        }
        Write-Progress -Activity "Gathering metadata" -Status "File: $($musicFile.FullName)" -PercentComplete (($musicFiles.IndexOf($musicFile) + 1) / $musicFiles.Count * 100)
    }


    Write-Host "Moving music files."
    foreach ($musicFile in $musicFiles) {
        $album = $fileMetadata[$musicFile.FullName]["Album"]
        $title = $fileMetadata[$musicFile.FullName]["Title"]
        $contributingArtists = $fileMetadata[$musicFile.FullName]["Contributing artists"]
        # $year = $fileMetadata[$musicFile.FullName]["Year"]
        $track = $fileMetadata[$musicFile.FullName]["#"]
        $disc = $fileMetadata[$musicFile.FullName]["Part of set"]

        Write-Host "File: $($musicFile.FullName)" -ForegroundColor Blue

        $artistFolderName = ConvertTo-FileName "$contributingArtists"
        $artistFolderName = $artistFolderName.Split(",")[0]
        $artistFolderName = $artistFolderName.Split(";")[0]
        $artistFolderName = $artistFolderName.Split(" feat.")[0]
        $artistFolder = Join-Path $Directory $artistFolderName
        if (!(Test-Path $artistFolder)) {
            if ($ActuallyMove) {
                New-Item -ItemType Directory -Path $artistFolder
            }
        }

        $albumFolderName = ConvertTo-FileName "$album"
        # if ($year) {
        #     $albumFolderName += " ($year)"
        # }
        $albumFolder = Join-Path $artistFolder $albumFolderName
        if (!(Test-Path $albumFolder)) {
            if ($ActuallyMove) {
                New-Item -ItemType Directory -Path $albumFolder
            }
        }

        
        $track = $track.PadLeft(2, "0")
        if ($disc) {
            $disc = $disc.Split("/")[0]
            $track = "$disc-$track"
        } else {
            $track = "1-$track"
        }

        $extension = Split-Path $musicFile.FullName -Extension
        $newFileName = ConvertTo-FileName "$track $title$extension"

        $newFilePath = Join-Path $albumFolder $newFileName
        if (!(Test-Path $newFilePath)) {
            Write-Host "Moving file to: $newFilePath" -ForegroundColor Green
            if ($ActuallyMove) {
                Move-Item -Path $musicFile.FullName -Destination $newFilePath
            }
        }
    }

    # find all empty directories and delete them
    do {
        $emptyDirectories = Get-ChildItem -Path $Directory -Recurse -Directory | Where-Object { $_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0 }
        foreach ($emptyDirectory in $emptyDirectories) {
            Write-Host "Deleting empty directory: $($emptyDirectory.FullName)" -ForegroundColor Red
            if ($ActuallyDelete) {
                Remove-Item -Path $emptyDirectory.FullName -Recurse
            }
        }
    } while ($emptyDirectories.Count -gt 0 -and $ActuallyDelete)
}

end {
    
}