function Disable-MSPIMDirectoryRoleAssignment
{
    <#
    .SYNOPSIS
    Disable PIM role

    .DESCRIPTION
    The Disable-MSPIMDirectoryRoleAssignment cmdlet is used to disable a current active PIM role.

    .PARAMETER RoleName
    Specifies the particular Azure role name to disable.

    .PARAMETER RoleId
    Specifies the particular Azure role id to disable

    .LINK
    https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http#example-3-user-deactivates-an-assigned-role

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = 'Unknown')]
    param(
        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Reason for elevation')]
        [ValidateNotNullOrEmpty()]
        [string]$Reason
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'unknown'
            {
                Write-Error 'You must provide either a RoleId or RoleName'
                return $null
            }
            'rolename'
            {
                $RoleName = $PSBoundParameters['RoleName']
                $roleDefinitionId = $global:roleName2Id.Item($RoleName)
                break
            }
            'roleid'
            {
                $roleDefinitionId = $PSBoundParameters['RoleId']
                break
            }
        }

        # $SubjectId = (Get-MSGObject  -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "me" -Filter "`$select=id").Id
        $activeRole = $myRoles.Where( { $_.RoleDefinitionId -eq $roleDefinitionId })

        $disableBody = [PSCustomObject][Ordered]@{
            roleDefinitionId               = $activeRole.RoleDefinitionId
            resourceId                     = $activeRole.resourceId
            subjectId                      = $activeRole.subjectId
            assignmentState                = $activeRole.AssignMentState
            type                           = 'UserRemove'
            linkedEligibleRoleAssignmentId = $activeRole.linkedEligibleRoleAssignmentId
        }

        if (-not [string]::IsNullOrEmpty($Reason))
        {
            Add-Member -InputObject $disableBody -MemberType NoteProperty -Name 'reason' -Value $Reason 
        }

        Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/aadroles/roleAssignmentRequests' -Method POST -Body $disableBody -ObjectName 'MSPIM'
    }
}
