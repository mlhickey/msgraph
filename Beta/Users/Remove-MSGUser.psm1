function Remove-MSGUser
{
    <#
    .SYNOPSIS
    Removes the specifed user from Azure Active Directory

    .DESCRIPTION
    The Remove-MSGUser cmdlet removes a user from Azure Active Directory

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-delete?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id
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
        if ($PSCmdlet.ShouldProcess("$Id", "Delete user"))
        {
            $id = [uri]::EscapeDataString($id)
            Set-MSGObject -Type "users" -Id $Id -Method DELETE
        }
    }
}
