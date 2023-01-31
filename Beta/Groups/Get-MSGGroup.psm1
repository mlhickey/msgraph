function Get-MSGGroup
{
    <#
    .SYNOPSIS
    Get group information

    .DESCRIPTION
    The Get-MSGGroup cmdlet gets information about groups in Azure Active Directory (Azure AD).

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER GroupType
    Specifies the type of group
        - DynamicMembership
        - Unified
        - Elevated

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .PARAMETER AdvancedQuery
    Sets header to support advanced query options (see https://docs.microsoft.com/en-us/graph/aad-advanced-queries#support-for-filter-on-properties-of-azure-ad-directory-objects)

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE
    Get-MSGGroup -SearchString "__MDM" -Properties displayName,id

    id                                   displayName
    --                                   -----------
    67e85905-5809-4dcc-92d0-9ef5def8aa54 __MDM__

    .EXAMPLE
    Get-MSGGroup -GroupType DynamicMembership -CountOnly
    122

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-get?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        # UserprincipalName or objectId
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the group.")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "Type of group: DynamicMembership, Unified or Elevated")]
        [ValidateSet(
            "DynamicMembership",
            "Unified",
            "Elevated")]
        [string]$GroupType,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search",
            HelpMessage = "Search criteria.")]
        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Filter",
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [string]$Filter,

        [Parameter(ParameterSetName = "Id",
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [Parameter(ParameterSetName = "Filter")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$All,

        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$AdvancedQuery,

        [Parameter(ParameterSetName = "Count")]
        [switch]$CountOnly
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }

        if (-not [string]::IsNullOrEmpty($GroupType))
        {
            if ([string]::IsNullOrEmpty($PSBoundParameters['Filter']))
            {
                $PSBoundParameters.Add('Filter', "groupTypes/any(c:c eq '$GroupType')")
            }
            else
            {
                $PSBoundParameters['Filter'] += "and (groupTypes/any(c:c eq '$GroupType'))"
            }
        }

        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {

            "id"
            {
                Get-MSGObject -Type "groups/$id" -Filter $queryFilter
                break
            }
            "osearch"
            {
                Get-MSGObject -Type "groups" -SearchString "startswith(displayName,'$SearchString')" -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            { $PSItem -match "topall|search" }
            {
                Get-MSGObject -Type "groups" -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            "count"
            {
                Get-MSGObject -Type "groups" -Filter $queryFilter -CountOnly
            }
        }
    }
}
