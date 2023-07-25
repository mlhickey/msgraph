function Get-MSGConfig
{

    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) '.msgraph\config.csv'
    $res = $null

    if (Test-Path -Path $ConfigPath)
    {
        $fileLock = [System.Threading.ReaderWriterLockSlim]::new()
        if ($fileLock.TryEnterReadLock(($global:_MSGMaxRetry * 5)))
        {
            try
            {
                $res = Import-Csv -Path $ConfigPath
            }
            finally
            {
                if ($fileLock.IsReadLockHeld)
                {
                    $fileLock.ExitReadLock()
                }
            }
        }
    }
    $res
}