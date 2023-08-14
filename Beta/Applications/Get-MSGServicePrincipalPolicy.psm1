function Get-MSGServicePrincipalPolicy
{
    <#
    .SYNOPSIS
    Returns a list of Policies for the specified service principal id.

    .DESCRIPTION
    The Get-MSGServicePrincipalPolicy cmdlet teturns a list of Policies for the specified service principal id.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-beta
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Policy type to retrieve: ClaimsMapping, HomeRealmDiscovery, TokenLifetime, TokenIssuance')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('ClaimsMapping', 'HomeRealmDiscovery', 'TokenLifetime', 'TokenIssuance')]
        [string]$PolicyType
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        if (-not [string]::IsNullOrEmpty($properties))
        {
            $propFilter = "`$select="
            $propFilter += $properties -join ', '
        }
    }

    process
    {
        $type = '{0}Policies' -f (camelCase $PolicyType)
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id/$type"
    }
}
