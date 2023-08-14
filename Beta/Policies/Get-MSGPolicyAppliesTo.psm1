function Get-MSGPolicyAppliesTo
{
    <#
    .SYNOPSIS
        Get application(s) and servicePrincipal(s) that the specified policy Id is applied to.

    .DESCRIPTION
        Get application(s) and servicePrincipal(s) that the specified policy Id is applied to.

    .PARAMETER Id
    Specifies the id (ObjectID) of a Policy in Azure AD

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER PolicyType
    Specifies the type of policy - ActivityBasedTimeout, ClaimsMapping, HomeRealmDiscovery or TokenLifetime

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all Policys. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGPolicyAppliesTo -Id 73c196e8-a690-4d60-85dc-e6ca7f2ca14a -Properties id,displayName

    @odata.type                       id                                   displayName
    -----------                       --                                   -----------
    #microsoft.graph.servicePrincipal cfea93f0-7b63-4649-914e-add7438fd659 Leaves@Microsoft Staging

    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/policy_list_appliesto
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the Policy.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Policy type: ActivityBasedTimeout, ClaimsMapping, HomeRealmDiscovery or TokenLifetime')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('ActivityBasedTimeout', 'ClaimsMapping', 'HomeRealmDiscovery', 'TokenLifetime')]
        [string]$PolicyType,

        [Parameter(Mandatory = $false,
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            HelpMessage = 'Partial/complete displayname of the policy.')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(Mandatory = $false)]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
        #$policy = $policyType.Substring(0, 1).ToLower() + $policyType.Substring(1) + "Policies"
        $policy = '{0}Policies' -f (camelCase $PolicyType)

    }

    process
    {
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "policies/$policy/$Id/appliesTo" -Filter $queryFilter
    }
}

