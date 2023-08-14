
function Get-DelegatedAuthentication
{
    [CmdletBinding()]
    param()

    process
    {
        throw 'Get-DelegatedAuthentication deprecated'
        $MSGAuthInfo = Get-MSGConfig
        if ($null -ne $MSGAuthInfo.DAToken)
        {
            $timeLeft = (($MSGAuthInfo.DAToken.Expiration - (Get-Date -UFormat '%s')) - 28800)
            if ($timeLeft -gt 300)
            {
                return $MSGAuthInfo.DAToken.access_token
            }
        }
        $Params = [ordered]@{
            'AuthType'               = 'Delegated'
            'AuthenticationEndpoint' = $MSGAuthInfo.Authority
            'EndPoint'               = $MSGAuthInfo.GraphUrl
            'TenantId'               = $MSGAuthInfo.TenantId
            'ClientId'               = $MSGAuthInfo.DelegatedCliendId
            'Secret'                 = 'ReportingAPISecret'
            'StoreLocation'          = 'KeyVault'
            'KeyVaultURI'            = $MSGAuthInfo.DelegateVault
        }

        if (-not [string]::IsNullOrEmpty($RedirectUri))
        {
            $Params.Add('RedirectUri', $RedirectUri)
        }

        $MSGAuthInfo.DAToken = Get-AzureADAccessToken @Params
        return $MSGAuthInfo.DAToken.AccessToken
    }
}

