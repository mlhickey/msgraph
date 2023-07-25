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
    $fileLock = [System.Threading.ReaderWriterLockSlim]::new()

    if ($fileLock.TryEnterWriteLock(($global:_MSGMaxRetry * 5)))
    {
        try
        {
            $configObject | Export-Csv -Path $ConfigPath -NoTypeInformation
        }

        finally
        {
            if ($fileLock.IsWriteLockHeld)
            {
                $fileLock.ExitWriteLock()
            }
        }
    }
}