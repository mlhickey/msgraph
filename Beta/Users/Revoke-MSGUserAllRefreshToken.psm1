function Revoke-MSGUserAllRefreshToken
{
    <#
    .SYNOPSIS
    Invalidate all refresh tokens for the specifed user

    .DESCRIPTION
    The Revoke-MSGUserAllRefreshToken cmdlet invalidates all of the user's refresh tokens issued to applications

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-invalidateallrefreshtokens?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the user.')]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id
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
        $idString = '{0}/invalidateAllRefreshTokens' -f $Id
        Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'users' -Id $idString -Method POST
    }
}
