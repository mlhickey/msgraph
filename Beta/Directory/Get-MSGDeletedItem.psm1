function Get-MSGDeletedItem
{
    <#
    .SYNOPSIS
    Get deleted items from Azure Active Directory

    .DESCRIPTION
    The Get-MSGDeletedItem cmdlet returns a list of deleted items.  This cmdlet currently supports retrieving object types of groups (microsoft.graph.group) or users (microsoft.graph.user) from deleted items

    .PARAMETER Id
    Specifieds the id (ObjectId) of a deleted object

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Type
    Specifies the type of item to return: User or Grpoup

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE
    Get-MSGDeletedItem -Type User -Top 1 -properties displayName,deletedDateTime

    deletedDateTime      displayName
    ---------------      -----------
    2018-07-31T19:05:58Z COMMAOC

    .LINK
     https://docs.microsoft.com/en-us/graph/api/directory-deleteditems-list?view=graph-rest-beta&tabs=http

    #>

    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the object")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,
        [Parameter(Mandatory = $true,
            ParameterSetName = "TopAll",
            HelpMessage = "Type of deleted directory object to return: Application, User or Group")]
        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "Filter")]
        [ValidateSet(
            "Application",
            "User",
            "Group")]
        [string]$Type,

        [Parameter(
            ParameterSetName = "Filter",
            HelpMessage = "OData query filter")]
        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(ParameterSetName = "Id",
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Filter")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Filter")]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$All,

        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
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

        if (-not [string]::IsNullOrEmpty($Id))
        {
            $queryFilter += "(id eq '$id')"
        }

        $queryFilter += ProcessBoundParams -paramList $PSBoundParameters
        $queryFilter = $queryFilter -join "&"
        $ItemType = "directory/deletedItems/microsoft.graph." + $Type.ToLower()
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                Get-MSGObject -Type $ItemType -Filter $queryFilter
                break
            }
            "count"
            {
                Get-MSGObject -Type $ItemType -Filter $queryFilter -CountOnly
                break
            }
            default
            {
                Get-MSGObject -Type $ItemType -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
