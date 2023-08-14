function Get-MSGConditionalAccessNamedLocation
{
    <#
    .SYNOPSIS
    Retrieve Azure Conditional Access policies

    .DESCRIPTION
    The Get-MSGConditionalAccessNamedLocation cmdlet will return a list of locations of the specified type

    .PARAMETER Id
    Specifies the Id (ObjectId) of a named location in Azure AD.

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE

    .LINK
     https://docs.microsoft.com/en-us/graph/api/resources/namedlocation?view=graph-rest-beta

    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the policy.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

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
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

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
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "conditionalAccess/namedLocations/$id"
                break
            }
            { $PSItem -match 'topall|search' }
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'conditionalAccess/namedLocations' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            'count'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'conditionalAccess/namedLocations' -Filter $queryFilter -CountOnly
            }
        }
    }
}
