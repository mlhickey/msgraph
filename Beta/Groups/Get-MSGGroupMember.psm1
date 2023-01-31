function Get-MSGGroupMember
{
    <#
    .SYNOPSIS
    Get group membership information

    .DESCRIPTION
    The Get-MSGGroupMember cmdlet gets mebership of the specified group in Azure Active Directory (Azure AD).

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .PARAMETER Recurse
    If true, recurse throught nested membership.  This could take a long time.

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE
     Get-MSGGroupMember -Id 67e85905-5809-4dcc-92d0-9ef5def8aa54 -SearchString "Mike" -Properties displayName

    displayName
    -----------
    Mike Hickey

    .EXAMPLE
    Get-MSGGroupMember -Id 67e85905-5809-4dcc-92d0-9ef5def8aa54 -Properties displayName

    displayName
    -----------
    Mike Hickey

    .EXAMPLE
     Get-MSGGroupMember -Id 67e85905-5809-4dcc-92d0-9ef5def8aa54 -CountOnly
    10

    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/group_list_members
    #>

    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    [Alias('Get-MSGGroupMembership')]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the group")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search",
            HelpMessage = "Search criteria.")]
        [Parameter(ParameterSetName = "Id")]
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

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$All,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$AdvancedQuery,

        [Parameter(ParameterSetName = "Id")]
        [Parameter(ParameterSetName = "Filter")]
        [Parameter(ParameterSetName = "Count")]
        [switch]$CountOnly,

        [switch]$Recurse
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        if ($Recurse)
        {
            $queryString = "groups/{0}/transitiveMembers" -f $id
        }
        else
        {
            $queryString = "groups/{0}/members" -f $id
        }

        Get-MSGObject -Type $queryString -All:$All -Filter $queryFilter -CountOnly:$CountOnly
    }
}
