function Get-MSGGroupMemberOf
{
    <#

    .SYNOPSIS
    Get group information

    .DESCRIPTION
    The Get-MSGGroupMemberOf cmdlet returns groups which the specified group is a member of.
    Note: The maximum number of groups each request can return is 2046.

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER QueryType
    Return membership based on the following query type.  Default is Direct
        - Direct
        - Transitive

    .PARAMETER OnlySGs
    Return only security groups

    .EXAMPLE
    Get-MSGGroupMemberOf -Id 0d9bd5ea-4b78-4e3b-ada0-25492c407fcb
    ca112e0f-9bc7-4636-b6cd-8c54774b56ee

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-getmembergroups?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
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
            HelpMessage = "Return only security groups")]
        [switch]$OnlySGs,

        [Parameter(Mandatory = $false,
            HelpMessage = "Get either direct or transitive membership of specifed group")]
        [ValidateSet("Direct", "Transitive")]
        [string]$QueryType = "Direct"
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {

        $body = @{ "securityEnabledOnly" = $OnlySGs.IsPresent }

        if ($queryType -match "Direct")
        {
            $queryCmd = "getMemberGroups"
        }
        else
        {
            $queryCmd = "getMemberObjects"
        }
        $type = "groups/{0}/{1}" -f $Id, $queryCmd
        Get-MSGObject -Type $type -Method POST -Body $body
    }
}
