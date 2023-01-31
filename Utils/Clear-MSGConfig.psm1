function Clear-MSGConfig
{
    [CmdletBinding()]
    [Alias("Disconnect-MSG")]
    param()

    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) ".msgraph\config.csv"
    $MSGAuthInfo = Get-MSGConfig
    if ((Test-Path -Path $ConfigPath -PathType Leaf))
    {
        try
        {
            $null = Remove-Item -Path $ConfigPath -Force
        }
        catch
        {
            throw "Failed to clear session configuration information"
        }
        Get-AzureADAccessToken -ClearAppIdCache $MSGAuthInfo.ClientId
    }
}