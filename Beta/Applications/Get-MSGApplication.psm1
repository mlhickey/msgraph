function Get-MSGApplication
{
    <#
    .SYNOPSIS
    Get application information

    .DESCRIPTION
    The Get-MSGApplication cmdlet gets an Azure Active Directory application

    .PARAMETER Id
    Specifies the Id (ObjectId) of an application in Azure AD.

    .PARAMETER AppId
    Specifies the application Id of an application in Azure AD.

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the oData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all application objects. If false, return the number of objects specified by the Top parameter

    .PARAMETER AdvancedQuery
    Sets header to support advanced query options (see https://docs.microsoft.com/en-us/graph/aad-advanced-queries#support-for-filter-on-properties-of-azure-ad-directory-objects)

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE
    Get-MSGApplication -SearchString "reporting" -top 1

    Id                                   AppId                                DisplayName                       SignInAudience
    --                                   -----                                -----------                       --------------
    000edc73-14ab-48fd-b3f1-67475bf6e89c 82b44d02-ae1e-4210-b669-3e2d3fd24326 PFX.FinancialReporting.DevOps.INT AzureADMyOrg

    .EXAMPLE
    Get-MSGApplication -SearchString "reporting" -CountOnly
    663

    .EXAMPLE
    Get-MSGApplication -AppId 82b44d02-ae1e-4210-b669-3e2d3fd24326

    Id                                   AppId                                DisplayName                       SignInAudience
    --                                   -----                                -----------                       --------------
    000edc73-14ab-48fd-b3f1-67475bf6e89c 82b44d02-ae1e-4210-b669-3e2d3fd24326 PFX.FinancialReporting.DevOps.INT AzureADMyOrg

    .EXAMPLE

    .LINK
    https://docs.microsoft.com/en-us/graph/api/application-list?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the object')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'AppId of the associated application')]
        [ValidateNotNullOrEmpty()]
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

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'AppId')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'Property to expand. Note that these are case sensitive')]
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
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "applications/$id" -Filter $queryFilter
                break
            }
            'appid'
            {
                if ([string]::IsNullOrEmpty($queryFilter))
                {
                    $queryFilter = "appid eq '$AppId'"
                }
                else
                {
                    $queryFilter = "appid eq '$AppId'&" + $queryFilter
                }
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'applications' -Filter $queryFilter
                break
            }
            { $PSItem -match 'topall|search' }
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'applications' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            'count'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'applications' -Filter $queryFilter -CountOnly
            }
        }
    }
}
