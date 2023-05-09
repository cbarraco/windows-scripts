[CmdletBinding()]
param (
    
)

begin {
    
}

process {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Fusion" -Name "EnableLog" -Value 1
}

end {
    
}