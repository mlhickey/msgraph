function Get-MSGServicePrincipal
{
    <#
    .SYNOPSIS
    Get service principal information

    .DESCRIPTION
    The Get-MSGServicePrincipal cmdlet gets a service principal in Azure Active Directory (Azure AD).

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER AppId
    Specifies the service principal application Id of an service principal in Azure AD.

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all serviceprincipal objects. If false, return the number of objects specified by the Top parameter

    .PARAMETER AdvancedQuery
    Sets header to support advanced query options (see https://docs.microsoft.com/en-us/graph/aad-advanced-queries#support-for-filter-on-properties-of-azure-ad-directory-objects)

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE
     Get-MSGServicePrincipal -SearchString "reporting" -top 1

    Id                                   AppId                                DisplayName                                                                SignInAudience
    --                                   -----                                -----------                                                                --------------
    00042ccf-f30d-4161-8e37-d938fa67ecfd 5925c582-83eb-462d-a241-f89e54beb15b SPI-searchPlatform.PerfMetric.Exec_c11_VC_AP_ALL.reporting2-prod-co01.co01 AzureADMyOrg

    .EXAMPLE
    Get-MSGServicePrincipal -SearchString "reporting" -CountOnly
    834

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-beta
    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the serviceprincipal')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'AppId of the associated application')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(
            ParameterSetName = 'Search',
            HelpMessage = 'Search criteria.')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(
            ParameterSetName = 'Filter',
            HelpMessage = 'OData query filter')]
        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'AppId')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(
            ParameterSetName = 'Id',
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'AppId')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'Property to expand. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'My')]
        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [string]$ExpandProperty,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]$All,

        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]$AdvancedQuery,

        [Parameter(ParameterSetName = 'Count')]
        [switch]$CountOnly
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id" -Filter $queryFilter
                break
            }
            'appid'
            {
                if ([string]::IsNullOrEmpty($queryFilter))
                {
                    $queryFilter = "Appid eq '$AppId'"
                }
                else
                {
                    $queryFilter = @("Appid eq '$AppId'", $queryFilter) -join '&'
                }
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'servicePrincipals' -Filter $queryFilter
                break
            }
            { $PSItem -match 'topall|search' }
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'servicePrincipals' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
            }
            'count'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'servicePrincipals' -Filter $queryFilter -CountOnly
            }
        }
    }
}
