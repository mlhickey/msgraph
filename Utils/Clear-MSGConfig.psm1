function Clear-MSGConfig
{
    [CmdletBinding()]
    [Alias('Disconnect-MSG')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the specific resource')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$ApplicationId
    )

    $ConfigPath = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) '.msgraph\config.csv'

    if ((Test-Path -Path $ConfigPath -PathType Leaf))
    {
        try
        {
            $null = Remove-Item -Path $ConfigPath -Force
        }
        catch
        {
            throw 'Failed to clear session configuration information'
        }
        Get-AzureADAccessToken -ClearCache:$true -ErrorAction SilentlyContinue
    }
}