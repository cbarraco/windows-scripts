[CmdletBinding()]
param (
    
)

begin {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
}

process {
    New-Item -Path "HKCR:\.apk\shell\InstallApk"
    New-ItemProperty -Path "HKCR:\.apk\shell\InstallApk" -Name "(Default)" -Value "&Install on Android Device"
    New-ItemProperty -Path "HKCR:\.apk\shell\InstallApk" -Name "Icon" -Value "C:\Windows\System32\cmd.exe"

    New-Item -Path "HKCR:\.apk\shell\InstallApk\command"
    New-ItemProperty -Path "HKCR:\.apk\shell\InstallApk\command" -Name "(Default)" -Value "C:\Windows\System32\cmd.exe /C `"adb install `"`"%V`"`"`""
}

end {
    
}