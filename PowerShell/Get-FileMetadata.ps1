[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $Path
)

begin {
    
}

process {
    $shell = New-Object -ComObject Shell.Application
    $file = Get-Item $Path
    $folder = $shell.Namespace($file.DirectoryName)
    $item = $folder.ParseName($file.Name)
    $fileMetadata = @{}
    foreach ($property in 0..300) {
        $name = $folder.GetDetailsOf($folder.Items, $property)
        $value = $folder.GetDetailsOf($item, $property)
        Write-Host "$property. $name = $value"
        $fileMetadata[$name] = $value
    }
    return $fileMetadata
}

end {
    
}