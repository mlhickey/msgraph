function Get-MSGUserSponsor
{
    <#
    .SYNOPSIS
    Get application assignments

    .DESCRIPTION
    The Get-MSGUserSponsor cmdlet gets the maanger for the specified user(s)

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER MyUser
    Returns information based on the current authenticated user

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-list-Sponsor?view=graph-rest-beta
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'My')]
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $id = [uri]::EscapeDataString($id)
                $typeString = 'users/{0}/sponsors' -f $Id
                break
            }
        }

        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $typeString -All
    }
}
