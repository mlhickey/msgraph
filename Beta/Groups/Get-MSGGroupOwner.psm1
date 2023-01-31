function Get-MSGGroupOwner
{
    <#
    .SYNOPSIS
    Gets a device from Azure Active Directory

    .DESCRIPTION
    The Get-MSGGroupOwner cmdlet gets the owners associated with the specified group

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .EXAMPLE
    Get-MSGGroupOwner -Id 67e85905-5809-4dcc-92d0-9ef5def8aa54 -Properties displayName

    displayName
    -----------
    Mike Hickey (EA SC ALT)

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-list-owners?view=graph-rest-beta&tabs=http

  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the group")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $groupList = @()
        $fmtString = "groups/{0}/owners"
        $null = $PSBoundParameters.Remove("SearchString")
        $propFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                $queryString = [string]::Format($fmtString, $Id)
                break
            }
            "search"
            {
                try { $groupList = ProcessGroupSearchString -SearchString $SearchString }
                catch { return $null }
                $group = $groupList
                $queryString = [string]::Format($fmtString, $group.Id)
                break
            }
        }

        Get-MSGObject -Type $queryString -All -Filter $propFilter
    }
}
