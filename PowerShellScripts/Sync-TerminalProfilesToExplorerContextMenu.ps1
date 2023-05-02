[CmdletBinding()]
param (
    
)

begin {
    $settingsJsonPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
}

process {
    Remove-Item -Path "HKCR:\Directory\shell\WindowsTerminal" -Force -Recurse | Out-Null
    New-Item -Path "HKCR:\Directory\shell\WindowsTerminal" -Force | Out-Null
    New-ItemProperty -Path "HKCR:\Directory\shell\WindowsTerminal" -Name "MUIVerb" -Value "&Windows Terminal" -Force | Out-Null
    New-ItemProperty -Path "HKCR:\Directory\shell\WindowsTerminal" -Name "ExtendedSubCommandsKey" -Value "Directory\\ContextMenus\\WindowsTerminal" -Force | Out-Null
    New-Item -Path "HKCR:\Directory\Background\shell\WindowsTerminal" -Force | Out-Null
    New-ItemProperty -Path "HKCR:\Directory\Background\shell\WindowsTerminal" -Name "MUIVerb" -Value "&Windows Terminal" -Force | Out-Null
    New-ItemProperty -Path "HKCR:\Directory\Background\shell\WindowsTerminal" -Name "ExtendedSubCommandsKey" -Value "Directory\\ContextMenus\\WindowsTerminal" -Force | Out-Null
    
    Remove-Item -Path "HKCR:\Directory\ContextMenus\WindowsTerminal" -Force -Recurse | Out-Null
    New-Item -Path "HKCR:\Directory\ContextMenus\WindowsTerminal" -Force | Out-Null
    New-Item -Path "HKCR:\Directory\ContextMenus\WindowsTerminal\shell" -Force | Out-Null

    $settingsJson = Get-Content -Path $settingsJsonPath -Raw | ConvertFrom-Json
    $profiles = $settingsJson.profiles.list
    $profiles | ForEach-Object {
        $settingsProfile = $_
        $profileName = $settingsProfile.name
        if ($settingsProfile.commandline) {
            $exePath = $settingsProfile.commandline
            Write-Host "Commandline found for profile $($profileName): $($settingsProfile.commandline)"
        } elseif ($settingsProfile.source) {
            $package = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.PackageFamilyName -eq $settingsProfile.source }
            if ($package) {
                Write-Host "AppX Package found for profile $($profileName): $($package.Name)"
                $packagePath = $package.InstallLocation
                Write-Host "Package path: $packagePath"
                $appXManifestPath = "$packagePath\AppxManifest.xml"
                [xml] $appXManifestXml = Get-Content -Path $appXManifestPath
                $exeName = $appXManifestXml.Package.Applications.Application.Executable
                Write-Host "Executable name: $exeName"
                $exePath = "$packagePath\$exeName"
                Write-Host "Executable path: $exePath"
            } else {
                $exePath = (Get-Command wt).Source
            }
        } else {
            Write-Warning "No commandline or source found for profile: $profileName"
        }

        Write-Host "Creating context menu for profile: $profileName"
        
        New-Item -Path "HKCR:\Directory\ContextMenus\WindowsTerminal\shell\$profileName" -Force | Out-Null
        Set-ItemProperty -Path "HKCR:\Directory\ContextMenus\WindowsTerminal\shell\$profileName" -Name "(Default)" -Value "$profileName" -Force | Out-Null
        New-ItemProperty -Path "HKCR:\Directory\ContextMenus\WindowsTerminal\shell\$profileName" -Name "Icon" -Value "$exePath" -Force | Out-Null
        New-Item -Path "HKCR:\Directory\ContextMenus\WindowsTerminal\shell\$profileName\command" -Force | Out-Null
        Set-ItemProperty -Path "HKCR:\Directory\ContextMenus\WindowsTerminal\shell\$profileName\command" -Name "(Default)" -Value "wt -p `"$profileName`" -d `"%w`"" -Force | Out-Null
    }

    Stop-Process -Name explorer -Force
}

end {
    
}