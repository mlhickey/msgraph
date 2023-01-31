<#

ClientId for DSRE Graph Query, used instead of public PS endpoint.  Uses delegated permissions:

Azure Active Directory Graph
    Directory.AccessAsUser.All	Delegated	Access the directory as the signed-in user
    User.Read	                Delegated	Sign in and read user profile

Microsoft Graph
    Directory.AccessAsUser.All	Delegated	Access directory as the signed in user
    IdentityRiskEvent.Read.All	Delegated	Read identity risk event information
    IdentityRiskyUser.Read.All	Delegated	Read identity risky user information

#>
#$MSGAuthInfo.ClientId = "392aec2b-77bb-4316-9325-75c4f472c545"


<#
    Class or hashtable ...

class MSGEnvironment
{
    [string]$Name
    [string]$AzureEndpoint
    [string]$GraphEndpoint

    MSGEnvironment(
        [string]$n,
        [string]$a,
        [string]$g
    )
    {
        $this.Name = $n
        $this.AzureEndpoint = $a
        $this.GraphEndpoint = $g
    }
}

[System.Collections.ArrayList]$msgEnvironmentTable = @(
    [MSGEnvironment]::new("AzurePPE", "https://login.windows-ppe.net", "https://graph.microsoft-ppe.com"),
    [MSGEnvironment]::new("AzureCloud", "https://login.microsoftonline.com", "https://graph.microsoft.com"),
    [MSGEnvironment]::new("AzureUSGovernment", "https://login.microsoftonline.us", "https://graph.microsoft.us")
    [MSGEnvironment]::new("AzureUSDoD", "https://login.microsoftonline.us", "https://dod-graph.microsoft.us" )
)
#>

$msgEnvironmentTable = @{
    'AzurePPE'          = @('https://login.windows-ppe.net', 'https://graph.microsoft-ppe.com')
    'AzureCloud'        = @('https://login.microsoftonline.com', 'https://graph.microsoft.com')
    'AzureUSGovernment' = @('https://login.microsoftonline.us', 'https://graph.microsoft.us')
    'AzureUSDoD'        = @('https://login.microsoftonline.us', 'https://dod-graph.microsoft.us')
}

function Connect-MSG
{
    <#
    .SYNOPSIS
    Connects user to Azure AD

    .DESCRIPTION
    Connects with an authenticated account to use MSGraph cmdlets

    .PARAMETER AccountId
    Specifies the ID of an account.

    .PARAMETER ApplicationId
    Specifies the application ID of the service principal.

    .PARAMETER AzureEnvironmentName
    Specifies the name of the Azure environment. The acceptable values for this parameter are:

        - AzureCloud
        - AzurePPE

    The default value is AzureCloud.

    .PARAMETER CertificateName
    Specifies the certificate of a digital public key X.509 certificate

    .PARAMETER  CertificateThumbprint
    Specifies the certificate thumbprint of a digital public key X.509 certificate

    .PARAMETER Force
    Forces a complete re-authentication instead of refresh of existing session.

    .PARAMETER GraphVersion
    Specifies the version of MSGraph to use. The acceptable values for this parameter are:

        - V1.0
        - beta

    The default value is beta

    .PARAMETER StoreLocation
    Specifies the store location to use for certificate lookup  to use. The acceptable values for this parameter are:

        - CurrentUser
        - LocalMachine

    The default value is CurrentUser

    .PARAMETER KeyVaultURI
    Specifies the full URI for the KeyVault to use, e.g. https://mykv.vault.azure.net

    .PARAMETER KeyVaultSecret
    Specified the name of the secret to retrieve from KeyVault for authentication

    .PARAMETER TenantId
    Specifies the ID of a tenant.

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignment', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = 'User')]
    param(
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'v1.0',
            'beta')]
        [string]$GraphVersion,

        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'AzurePPE',
            'AzureCloud',
            'AzureUSGovernment',
            'AzureUSDoD')]
        [string]$AzureEnvironmentName,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'AppId')]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'AppId')]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateName,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'AppId')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'LocalMachine',
            'CurrentUser',
            'KeyVault')]
        [string]$StoreLocation,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'User')]
        [ValidateNotNullOrEmpty()]
        [string]$AccountId,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'User')]
        [Parameter(Mandatory = $False,
            ParameterSetName = 'AppId')]
        [Alias('ClientId')]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$ApplicationId,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'AppId')]
        [string]$KeyVaultURI,

        [Parameter(Mandatory = $False,
            ParameterSetName = 'AppId')]
        [string]$KeyVaultSecret,

        [Parameter(Mandatory = $False)]
        [switch]$Force
    )

    begin
    {
        $MSGAuthInfo = [PSCustomObject]@{
            AuthType          = $null
            DelegatedCliendId = $null
            DelegateVault     = $null
            TenantDomain      = $null
            TenantId          = $null
            GraphVersion      = $null
            GraphUrl          = $null
            Authority         = $null
            ClientId          = $null
            Environment       = $null
            User              = $null
            StoreLocation     = $null
            Initialized       = $false
        }

        if ($PSBoundParameters.Count)
        {
            Clear-MSGConfig
        }
        else
        {
            $MSGConfig = Get-MSGConfig
        }
        #region Validation
        if ([string]::IsNullOrEmpty($AzureEnvironmentName))
        {
            if ([string]::IsNullOrEmpty($MSGConfig.Environment))
            {
                $AzureEnvironmentName = 'AzureCloud'
            }
            else
            {
                $AzureEnvironmentName = $MSGConfig.Environment
            }
        }

        if ([string]::IsNullOrEmpty($StoreLocation))
        {
            if ([string]::IsNullOrEmpty($MSGConfig.StoreLocation))
            {
                $StoreLocation = 'CurrentUser'
            }
            else
            {
                $StoreLocation = $MSGConfig.StoreLocation
            }
        }

        if ([string]::IsNullOrEmpty($TenantId))
        {
            if (-not [string]::IsNullOrEmpty($MSGConfig.TenantId))
            {
                $TenantId = $MSGConfig.TenantId
            }
            elseif (-not [string]::IsNullOrEmpty($MSGConfig.TenantDomain))
            {
                $TenantId = $MSGConfig.TenantDomain
            }
            else
            {
                $TenantId = $TenantDomain = 'microsoft.onmicrosoft.com'
            }
        }

        if ([string]::IsNullOrEmpty($GraphVersion))
        {
            if ([string]::IsNullOrEmpty($MSGConfig.GraphVersion))
            {
                $GraphVersion = 'beta'
            }
            else
            {
                $GraphVersion = $MSGConfig.GraphVersion
            }
        }

        if ([string]::IsNullOrEmpty($ApplicationId))
        {
            if ([string]::IsNullOrEmpty($MSGConfig.ClientId))
            {
                $ApplicationId = '1b730954-1685-4b74-9bfd-dac224a7b894'
            }
            else
            {
                $ApplicationId = $MSGConfig.ClientId
            }
        }
        # Validate KeyVault parameters
        if ($PSBoundParameters['StoreLocation'] -eq 'KeyVault')
        {
            if (-not [string]::IsNullOrEmpty($PSBoundParameters['KeyVaultURI']))
            {
                Add-Member -InputObject $MSGAuthInfo  -MemberType NoteProperty -Name KeyVaultURI -Value $KeyVaultURI
            }
            else
            {
                throw 'A KeyVault URI must be supplied'
            }
        }
        #endregion Validation
        $MSGAuthInfo.TenantDomain = $TenantDomain
        $MSGAuthInfo.TenantId = $TenantId
        $MSGAuthInfo.DelegatedCliendId = $MSGConfig.DelegatedCliendId
        $MSGAuthInfo.DelegateVault = $MSGConfig.DelegateVault
        $MSGAuthInfo.GraphVersion = $GraphVersion
        $MSGAuthInfo.ClientId = $ApplicationId
        $MSGAuthInfo.Environment = $AzureEnvironmentName
        $MSGAuthInfo.User = $AccountId
        $MSGAuthInfo.StoreLocation = $StoreLocation
        $MSGAuthInfo.Initialized = $false

        $msgEnvironment = $msgEnvironmentTable[$MSGAuthInfo.Environment]
        $MSGAuthInfo.GraphUrl = $msgEnvironment[1]
        $MSGAuthInfo.Authority = $msgEnvironment[0]
        Set-MSGConfig -ConfigObject $MSGAuthInfo
    }

    process
    {
        $MSGAuthInfo = Get-MSGConfig
        $Params = @{
            'Tenant'        = $MSGAuthInfo.TenantId
            'ClientId'      = $MSGAuthInfo.ClientId
            'GraphEndPoint' = $MSGAuthInfo.GraphUrl
            'Authority'     = $MSGAuthInfo.Authority
        }

        if ([string]::IsNullOrEmpty($_MSGMaxRetry))
        {
            Set-Variable -Name _MSGMaxRetry -Scope Global -Value 5 -Option ReadOnly
        }

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'user'
            {
                if (-not [string]::IsNullOrEmpty($AccountId))
                {
                    $Params.Add('AccountId', $AccountId)

                }
                if ($Force) { $Params.Add('Force', $Force) }
                $MSGAuthInfo.AuthType = 'User'
                Set-MSGConfig -ConfigObject $MSGAuthInfo
                $res = Get-UserAuthenticationResult @Params
                break
            }

            'appid'
            {
                $Params.Add('StoreLocation', $StoreLocation)
                if (-not [string]::IsNullOrEmpty($CertificateThumbprint))
                {
                    $Params.Add('Thumbprint', $CertificateThumbprint)
                    Add-Member -InputObject $MSGAuthInfo  -MemberType NoteProperty -Name ThumbPrint -Value  $CertificateThumbprint
                }
                elseif (-not [string]::IsNullOrEmpty($CertificateName))
                {
                    $Params.Add('CertificateName', $CertificateName)
                    Add-Member -InputObject $MSGAuthInfo  -MemberType NoteProperty -Name Certificate -Value  $CertificateName
                }
                else
                {
                    throw 'Missing thumbprint or name for certificate to use'
                }
                $MSGAuthInfo.AuthType = 'App'
                $MSGAuthInfo.User = $MSGAuthInfo.ClientId
                Set-MSGConfig -ConfigObject $MSGAuthInfo
                $res = Get-AppAuthenticationResult @Params
                break
            }
        }

        $authInfo = Get-AzureAdAccessTokenInfo -AccessToken ($res -split ' ')[1]
        $scopes = $authInfo.scp

        $MSGAuthInfo = Get-MSGConfig
        $MSGAuthInfo.TenantId = $authInfo.tid

        if (![string]::IsNullOrEmpty($authInfo.upn))
        {
            $MSGAuthInfo.User = $authInfo.upn
        }
        Set-MSGConfig -ConfigObject $MSGAuthInfo
        $MSGAuthInfo.TenantDomain = ((Get-MSGOrganization -Properties verifieddomains).verifiedDomains | Where-Object isDefault -EQ $true).name
        Set-MSGConfig -ConfigObject $MSGAuthInfo
        if ($MSGAuthInfo.AuthType -eq 'User' -and $null -eq $global:PIMRoleDictionary)
        {
            Write-Output  'Setting up PIM role information ...'
            <#
            Yes, I hate using a global variable but the retrieval calls can be expensive so I persist through each invocation of Connect-MSG
            #>
            $global:PIMRoleDictionary = New-RoleMapping
            Write-Output 'Done!'
        }
        Get-MSGCurrentSession
    }
}
function Get-MSGCurrentSession
{
    <#
    .SYNOPSIS
    Returns the current session information

    .DESCRIPTION
    Returns the current session information

    .EXAMPLE
    Get-MSGCurrentSession

    Account               Environment TenantId                             TenantDomain              AccountType
    -------               ----------- --------                             ------------              -----------
    myuser@microsoft.com  AzureCloud  72f988bf-86f1-41af-91ab-2d7cd011db47 microsoft.onmicrosoft.com User

    #>

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
    }
    process
    {
        if ([string]::IsNullOrEmpty($MSGAuthInfo.TenantDomain))
        {
            $MSGAuthInfo.TenantDomain = ((Get-MSGOrganization -Properties verifieddomains).verifiedDomains | Where-Object isDefault -EQ $true).name
        }

        [PSCustomObject][Ordered]@{
            PSTypeName   = 'MSGraph.Account'
            Account      = $MSGAuthInfo.User
            Environment  = $MSGAuthInfo.Environment
            Scopes       = $scopes -split ' '
            TenantId     = $MSGAuthInfo.TenantId
            TenantDomain = $MSGAuthInfo.TenantDomain
            AccountType  = if ($MSGAuthInfo.AuthType -eq 'App') { 'ServicePrincipal' } else { $MSGAuthInfo.AuthType }
        }
    }
}

function Get-MSGProfile
{
    $MSGAuthInfo = Get-MSGConfig
    [PSCustomObject]@{
        Name        = $MSGAuthInfo.GraphVersion
        Description = "Microsoft Graph $($MSGAuthInfo.GraphVersion) API version"
    }
}
function Set-MSGProfile
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'v1.0',
            'beta')]
        [string]$GraphVersion
    )
    $MSGAuthInfo = Get-MSGConfig
    $MSGAuthInfo.GraphVersion = $GraphVersion
    Set-MSGConfig -ConfigObject $MSGAuthInfo
}

function Get-MSGEnvironmentList
{
    $msgEnvironmentTable
}

