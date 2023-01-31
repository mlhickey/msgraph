function Set-MSGConfig
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory = $true)]
        [object]$ConfigObject
    )
    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) ".msgraph"
    $mtx = New-Object System.Threading.Mutex($false, "LogfileMutex")


    if (-not (Test-Path -Path $ConfigPath))
    {
        $null = New-Item -Path $ConfigPath -ItemType Directory
    }
    $ConfigPath += "\config.csv"
    try
    {
        [void]$mtx.WaitOne()
        $null = ($configObject | Export-Csv -Path $ConfigPath -NoTypeInformation)
    }
    catch
    {
        throw "Failed to set session configuration information"
    }

    finally
    {
        $mtx.ReleaseMutex()
    }

}