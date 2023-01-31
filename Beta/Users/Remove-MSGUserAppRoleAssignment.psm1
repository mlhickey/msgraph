function Remove-MSGUserAppRoleAssignment
{
    <#
    .SYNOPSIS
    Remove user application role assignment

    .DESCRIPTION
    The Remove-MSGUserAppRoleAssignment cmdlet will remove an application role assignment from he specified user

    .PARAMETER Id
    Specifies the Id of the user

    .PARAMETER AppRoleAssignmentId
    Specifieds the id of the application role assignment

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-delete-approleassignments?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id or UserPrincipal.")]
        [Alias("ObjectId", "UserPrincipal")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the application role")]
        [string]$AppRoleAssignmentId

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
        if ($PSCmdlet.ShouldProcess("$Id", "Delete application assignment"))
        {
            Remove-MSGObject -Type "users/$id/appRoleAssignments" -Id $AppRoleAssignmentId
        }
    }
}
