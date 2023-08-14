function Remove-MSPIMDirectoryRoleAssignment
{
    <#
    .SYNOPSIS
    Get current PIM assignments

    .DESCRIPTION
    The Remove-MSPIMDirectoryRoleAssignments cmdlet removes the speciifed PIM role assignment from the specified user

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER RoleName
    Specifies the particular Azure role name to return.

    .PARAMETER RoleId
    Specifies the particular Azure role id to return

    .EXAMPLE
    Remove-MSPIMDirectoryRoleAssignments -RoleName 'Security Reader' -Id myuser@microsoft.com

    .EXAMPLE
    Import-CSV UserRevocation.csv | Remove-MSPIMDirectoryRoleAssignments -RoleName 'Security Reader'

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http#example-4-administrator-removes-user-from-a-role
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GUID of PIM role to enable')]
        [Alias('RoleDefinitionId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$RoleID,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the user.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Type of assignment to remove: Permanent or Eligible')]
        [ValidateSet(
            'Permanent',
            'Eligible')]
        [string]$AssignmentType = 'Eligible'
    )

    dynamicparam
    {
        if ($null -eq $global:PIMRoleDictionary)
        {
            $global:PIMRoleDictionary = New-RoleMapping
        }
        $global:PIMRoleDictionary
    }

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

        if (-not [string]::IsNullOrEmpty($PSBoundParameters['RoleName']))
        {
            $RoleName = $PSBoundParameters['RoleName']
            $RoleID = $global:roleName2Id.Item($RoleName)
        }

        if ([string]::IsNullOrEmpty($RoleID))
        {
            Write-Error 'You must supply a PIM role name or id'
            return $null
        }
        try
        {
            $null = [System.Guid]::New($id)
            $SubjectId = Get-MSGObjectById -Id $id -Filter "`$select=id"
            $SubjectId = $SubjectId.id
        }
        catch
        {
            $SubjectId = (Get-MSGUser -Id $id).id
        }

        $body = [PSCustomObject][Ordered]@{
            assignmentState  = $AssignmentType
            resourceId       = $MSGAuthInfo.TenantId
            roleDefinitionId = $RoleID
            subjectId        = $SubjectId
            type             = 'AdminRemove'
        }
        if ($PSCmdlet.ShouldProcess("$Id", 'Remove PIM assignment'))
        {
            Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/aadroles/roleAssignmentRequests' -Method POST -Body $body -ObjectName 'MSPIM'
        }
    }
}
