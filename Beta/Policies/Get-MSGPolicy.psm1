$policies = @{
    'ActivityBasedTimeout'                = 'activityBasedTimeoutPolicies'
    'Authorization'                       = 'authorizationPolicy'
    'ClaimsMapping'                       = 'claimsMappingPolicies'
    'HomeRealmDiscovery'                  = 'homeRealmDiscoveryPolicies'
    'TokenLifetime'                       = 'tokenLifetimePolicies'
    'TokenIssuance'                       = 'tokenIssuancePolicy'
    'IdentitySecurityDefaultsEnforcement' = 'identitySecurityDefaultsEnforcementPolicy'
    'PermissionGrantPolicies'             = 'permissionGrantPolicies'
}
function Get-MSGPolicy
{
    <#
    .SYNOPSIS
    Gets a Policy from Azure Active Directory

    .DESCRIPTION
    The Get-MSGPolicy cmdlet gets a Policy from Azure Active Directory

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

    Get-MSGPolicy -PolicyType ClaimsMapping -Top 1

    Id                                   DisplayName       Type IsOrganizationDefault
    --                                   -----------       ---- ---------------------
    ee5c7a9f-c6e2-4e1e-88ad-0b8c72a52762 EmployeeID_NameID      False


    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/Policy_list and https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/policy_get

#>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
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
    dynamicparam
    {
        [string[]]$options = @($policies.Keys | Sort-Object)
        $helpMessage = 'Policy type: {0}' -f ($options -join ', ')
        New-DynamicParam -Name Policy -ValidateSet $options -HelpMessage $helpMessage -ValueFromPipelineByPropertyName -Mandatory
    }

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters

        $policy = $policies.Item($PSBoundParameters['Policy'])
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "policies/$policy/$Id" -Filter $queryFilter
                break
            }

            { $PSItem -match 'topall|search' }
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "policies/$policy"-Filter $queryFilter -All:$All
                break
            }
        }
    }
}
