function Get-MSGUserMembership
{
    <#
    .SYNOPSIS
    Get all objects user is member of

    .DESCRIPTION
    The Get-MSGUserMembership cmdlet lists all objects the specified user is a member

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to Id and UserPrincipalName for named pipeline processing

    .PARAMETER OnlySGs
    Specifies whether only security enabled groups should be part of the result set.

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-getmemberobjects?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the User.')]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Return only security groups')]
        [switch]$OnlySGs
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
        $body = @{ 'securityEnabledOnly' = $OnlySGs.IsPresent }
        $typeString = 'users/{0}/getMemberObjects' -f $Id
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $typeString -Method POST -Body $body -All
    }
}
