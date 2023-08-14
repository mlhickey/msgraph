$clientCache = @{}
function Get-AppAuthenticationResult
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$graphEndPoint,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$tenant,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$clientId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$certificateName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$thumbPrint,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'LocalMachine',
            'CurrentUser',
            'KeyVault')]
        [string]$StoreLocation,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$authority,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyVaultURI
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($clientCache.ContainsKey($clientId))
        {
            $authResult = $clientCache.Item($clientId)
            if ($authResult.ExpiresOn -le (Get-Date))
            {
                $clientCache.Remove($clientId)
                $authResult = $null
            }
        }
    }

    process
    {
        if ($null -eq $authResult)
        {
            $authHeader = $null
            $Params = [ordered]@{
                'EndPoint'               = $graphEndPoint
                'TenantDomain'           = $tenant
                'ClientId'               = $clientId
                'AuthType'               = 'Application'
                'StoreLocation'          = $StoreLocation
                'AuthenticationEndpoint' = $authority
            }

            if ($StoreLocation.ToLower() -eq 'keyvault')
            {
                if ([string]::IsNullOrEmpty($KeyVaultURI))
                {
                    if ([string]::IsNullOrEmpty($MSGAuthInfo.KeyVaultURI))
                    {
                        throw 'Missing Keyvault URI'
                    }
                    else
                    {
                        $KeyVaultURI = $MSGAuthInfo.KeyVaultURI
                    }
                }
                $Params.Add('KeyVaultURI', $KeyVaultURI)
            }

            if (-not [string]::IsNullOrEmpty($thumbPrint))
            {
                $Params.Add('Thumbprint', $thumbPrint)
            }
            elseif (-not [string]::IsNullOrEmpty($certificateName))
            {
                $Params.Add('CertificateName', $certificateName)
            }

            try
            {
                $authResult = Get-AzureADAccessToken @Params
            }
            catch
            {
                $authResult = Get-AzureADAccessToken @Params
            }
        }

        if ($null -ne $authResult)
        {
            Write-Debug "[Get-AppAuthenticationResult]: - $((Get-AzureAdAccessTokenInfo -AuthToken $authResult).scp)"
            if (-not $clientCache.Contains($ClientId))
            {
                $clientCache.Add($ClientId, $authResult)
            }

            $authHeader = $authResult.CreateAuthorizationHeader()
            if ($null -eq $authResult.TenantId)
            {
                $MSGAuthInfo.TenantId = (Get-AzureAdAccessTokenInfo -AuthToken $authResult).tid
            }
            else
            {
                $MSGAuthInfo.TenantId = $authResult.TenantId
            }
            $MSGAuthInfo.Initialized = $true
            #Set-MSGConfig -ConfigObject $MSGAuthInfo
        }
        return $authHeader
    }
}
