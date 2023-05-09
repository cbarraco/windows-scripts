[CmdletBinding()]
param (
    
)

begin {
    
}

process {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DesktopLivePreviewHoverTime" -Value 0
}

end {
    
}