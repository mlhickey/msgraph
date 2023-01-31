function Get-MSGConfig
{
    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) ".msgraph\config.csv"
    if (Test-Path -Path $ConfigPath)
    {
        try
        {
            $mtx = New-Object System.Threading.Mutex($false, "LogfileMutex")
            [void]$mtx.WaitOne()
            Import-Csv -Path $ConfigPath
        }

        finally
        {
            $mtx.ReleaseMutex()
        }
    }
    else
    {
        return $null
    }
}