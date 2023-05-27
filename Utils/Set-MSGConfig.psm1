function Set-MSGConfig
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory = $true)]
        [object]$ConfigObject
    )
    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) '.msgraph'

    if (-not (Test-Path -Path $ConfigPath))
    {
        $null = New-Item -Path $ConfigPath -ItemType Directory
    }
    $ConfigPath += '\config.csv'

    try
    {
        $null = ($configObject | Export-Csv -Path $ConfigPath -NoTypeInformation)
    }
    catch
    {
        throw 'Unable to save config'
    }
}