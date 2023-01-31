function Get-MSGUserJoinedTeam
{
    <#
    .SYNOPSIS
    Get teams that user is member of

    .DESCRIPTION
    The Get-MSGUserJoinedTeam cmdlet returns a list of groups that the specified user is a member of.  The returned list is a collection of objectIds

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER MyUser
    Returns information based on the current authenticated user

    .EXAMPLE
    (Get-MSGUserJoinedTeam -Id user@microsoft.com).Count
    547

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-list-joinedteams?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the User.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,

        [Parameter(ParameterSetName = "My")]
        [switch]$MyUser
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

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                $id = [uri]::EscapeDataString($id)
                $typeString = "users/{0}/joinedTeams" -f $Id
                break
            }
            "my"
            {
                $typeString = "me/joinedTeams"
                break
            }
        }
        Get-MSGObject -Type $typeString -All
    }
}
