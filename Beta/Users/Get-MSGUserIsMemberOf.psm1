function Get-MSGUserIsMemberOf
{
    <#
    .SYNOPSIS
    Check if user is member of specified group(s)

    .DESCRIPTION
    The Get-MSGUserIsMemberOf cmdlet checks whether user is a member of the specified group(s).  Returned value(s) are the groups the user is a member of

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER GroupList
    Comma-separated list of group objectIds to check.  The API currently supports a maximum of 20 groups per query

    .EXAMPLE
    Get-MSGUserIsMemberOf -Id f839606d-4143-4ed4-a049-56c26049a343 -GroupList a266b757-931f-46cc-9153-9419e5596dfb,1a00142f-deed-4699-b792-e1339baa48ae
    a266b757-931f-46cc-9153-9419e5596dfb

    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/user_checkmembergroups
    #>
    [CmdletBinding()]
    [Alias('Check-MSGGroupMembership')]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the User.')]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'List of group IDs to check membership in')]
        [string[]]$GroupList
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    process
    {
        $id = [uri]::EscapeDataString($id)
        $body = @{ 'groupIds' = $GroupList }
        $typeString = 'users/{0}/checkMemberGroups' -f $Id
        #$typeString = "users/{0}/checkMemberObjects" -f $Id
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $typeString -Method POST -Body $body
    }
}
