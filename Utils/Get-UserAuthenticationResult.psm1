function Get-UserAuthenticationResult
{
    <#
    .SYNOPSIS
    Return an Azure authentication token to be used for calls to Graph

    .DESCRIPTION
    Get-AzureADAccessToken is used to generate an Azure access token.  It uses ADAL to support MFA and accepts a number of parameters in an attempt
    to support the widest number of authentication providers.

    .PARAMETER tenant
    Specifies the tenant to be authentication to.

    .PARAMETER authBehavior
    Specifies the authentication behavior.  Accepts on of two arguments:

        Always - generate an authentication form regardless of current state
        AUto - optionally generate an authentication form depending on current auth state

    .PARAMETER graphEndPoint
    Specifies the Graph endpoint to use as authentication endpoint.  Default is https://graph.microsoft.com

    .PARAMETER clientId
    Azure client ID  for auth.  Default is Azure PowerShell clientID:  1950a258-227b-4e31-a9cf-717495945fc2

    .PARAMETER redirectUri
    Redirect URI for auth.  Default is Azure PowerShell redirectUri:  urn:ietf:wg:oauth:2.0:oob

    .PARAMETER authority
    URL of logon authority used for authentication.  Default is https://login.microsoftonline.com

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$tenant,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$authBehavior = 'Auto',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$graphEndPoint,

        [Parameter(Mandatory = $True)]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$clientId,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$authority,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$AccountId,

        [Parameter(Mandatory = $False)]
        [switch]$Force
    )

    $authHeader = $null
    $MSGAuthInfo = Get-MSGConfig
    if ($Force.IsPresent)
    {
        $authBehavior = 'Force'
    }
    $Params = @{
        'EndPoint'               = $graphEndPoint
        'PromptBehavior'         = $authBehavior
        'TenantDomain'           = $tenant
        'ClientId'               = $clientId
        'AuthType'               = 'User'
        'AuthenticationEndpoint' = $authority
    }
    # PS7 doesn't support interactive authN so need to flip to DeviceCode authN
    if ($PSVersionTable.PSVersion.Major -gt 5)
    {
        $Params.AuthType = 'DeviceCode'
    }

    if (-not [string]::IsNullOrEmpty($AccountId))
    {
        $Params.Add('AccountId', $AccountId)
    }
    try
    {
        $MSGAuthResult = Get-AzureADAccessToken @Params
    }
    catch
    {
        $Params.PromptBehavior = 'Select'
        $MSGAuthResult = $null
    }

    if ($null -eq $MSGAuthResult)
    {
        $MSGAuthResult = Get-AzureADAccessToken @Params
    }
    #
    # Update global variables to current values
    #
    if ($null -ne $MSGAuthResult)
    {
        $MSGAuthInfo.TenantId = $MSGAuthResult.TenantId
        # Check for ADAL-based results
        if ($null -ne $MSGAuthResult.UserInfo.DisplayableId)
        {
            $MSGAuthInfo.user = $MSGAuthResult.UserInfo.DisplayableId
        }
        # Check for MSAL-based results
        elseif ($null -ne $MSGAuthResult.Account.Username)
        {
            $MSGAuthInfo.user = $MSGAuthResult.Account.Username
        }
        $MSGAuthInfo.Initialized = $true
        #Set-MSGConfig -ConfigObject $MSGAuthInfo
        $authHeader = $MSGAuthResult.CreateAuthorizationHeader()
    }

    Write-Debug "[Get-UserAuthenticationResult]: - $((Get-AzureAdAccessTokenInfo -AuthToken $MSGAuthResult).scp)"
    return $authHeader
}
