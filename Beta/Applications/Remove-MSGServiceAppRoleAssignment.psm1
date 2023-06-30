function Remove-MSGServiceAppRoleAssignment
{
    <#
    .SYNOPSIS
    Assigns a service principal to an application role

    .DESCRIPTION
    The Remove-MSGServiceAppRoleAssignment cmdlet removes an application role assignment from a service principal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER ApproleAssignmentId
    Specifies the id of the resource role being removed

    .EXAMPLE
    Get-MSGServicePrincipalAppRoleAssignedTo -id 49223a9d-ba1b-4260-90a2-4571e42823d7 | select ResourceDisplayName,AppRoleName,Id

    resourceDisplayName appRoleName               id
    ------------------- -----------               --
    Microsoft Graph     Device.ReadWrite.All      TflOzfUvlUmVdHgSw52zmlPbA8-juolCtsDH7Jui2tU
    Microsoft Graph     User.ReadWrite.All        TflOzfUvlUmVdHgSw52zmlNfYH4Bt1FAt-Df39gro00
    Microsoft Graph     Application.ReadWrite.All TflOzfUvlUmVdHgSw52zmuxVhNE7Ok1NhWdMNwEPMeA
    Microsoft Graph     Organization.Read.All     TflOzfUvlUmVdHgSw52zmuEZPlTxK75IjclyUBwMExA
    Microsoft Graph     AuditLog.Read.All         TflOzfUvlUmVdHgSw52zms5wFzPmUOpCuQI7cvMzpGI

    Remove-MSGServiceAppRoleAssignment -Id 49223a9d-ba1b-4260-90a2-4571e42823d7 -ApproleAssignmentId TflOzfUvlUmVdHgSw52zmuxVhNE7Ok1NhWdMNwEPMeA

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-delete-approleassignedto?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal.')]
        [Alias('ObjectId', 'PrincipalId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the resource role .')]
        [ValidateNotNullOrEmpty()]
        [string]$ApproleAssignmentId
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
        if ($PSCmdlet.ShouldProcess("$Id", 'Remove approle ssignment'))
        {
            $res = Remove-MSGObject -Type "servicePrincipals/$id/appRoleAssignments" -Id $ApproleAssignmentId
            $global:lastexitcode = $res.StatusCode
        }
    }
}
