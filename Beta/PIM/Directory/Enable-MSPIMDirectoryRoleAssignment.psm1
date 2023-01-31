function Enable-MSPIMDirectoryRoleAssignment
{
    <#
    .SYNOPSIS
    Enable PIM role

    .DESCRIPTION
    The Enable-MSPIMDirectoryRoleAssignment cmdlet is used to enable an eligible PIM role.

    .PARAMETER RoleName
    Specifies the particular Azure role name to enable.

    .PARAMETER RoleId
    Specifies the particular Azure role id to return

    .EXAMPLE
    Enable-MSPIMDirectoryRoleAssignment -RoleName 'Security Reader' -Reason 'Log Review"

    .LINK
    https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http#example-2-user-activates-eligible-role

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = "Unknown")]
    param(
        [Parameter(ParameterSetName = "RoleId",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "GUID of PIM role to enable")]
        [Alias("RoleDefinitionId")]
        [string]$RoleID,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Reason for elevation")]
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
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "unknown"
            {
                Write-Error "You must provide either a RoleId or RoleName"
                return $null
            }

            "rolename"
            {
                $RoleName = $PSBoundParameters['RoleName']
                $roleId = $global:roleName2Id.Item($RoleName)
            }
        }
        $SubjectId = (Get-MSGObject -Type "me" -Filter "`$select=id").Id
        $Now = Get-Date ([datetime]::UtcNow) -UFormat "%Y-%m-%dT%H:%M:%SZ"

        $schedule = [PSCustomObject][Ordered]@{
            type          = "Once"
            startDateTime = $Now
            #'endDateTime'   = $Now.AddMinutes($ExpiryMinutes)
            duration      = $global:roleId2Name.Item($roleId).duration
        }

        $roleRequest = [PSCustomObject][Ordered]@{
            resourceId       = $MSGAuthInfo.TenantId
            roleDefinitionId = $roleId
            subjectId        = $SubjectId
            assignmentState  = "Active"
            type             = "UserAdd"
            reason           = $Reason
            schedule         = $schedule
        }

        Set-MSGObject -Type "privilegedAccess/aadroles/roleAssignmentRequests" -Body $roleRequest -Method POST -ObjectName "MSPIM"
    }
}

