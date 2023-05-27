function Get-MSGConfig
{

    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) '.msgraph\config.csv'
    $res = $null


    if (Test-Path -Path $ConfigPath)
    {
        $res = Import-Csv -Path $ConfigPath
    }
    $res
}