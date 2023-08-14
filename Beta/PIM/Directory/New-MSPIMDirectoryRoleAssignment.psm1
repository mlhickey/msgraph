function New-MSPIMDirectoryRoleAssignment
{
    <#
    .SYNOPSIS
    Creates a new PIM assignment

    .DESCRIPTION
    The New-MSPIMDirectoryRoleAssignments cmdlet assigns the speciifed PIM role assignment to the specified user

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER RoleName
    Specifies the particular Azure role name to assign.

    .PARAMETER RoleId
    Specifies the particular Azure role id to assign

    .PARAMETER Action
    Specifies the type of action being requested:

            Add
            Extend
            Renew
            Update

    Default is Add

    .PARAMETER AssignmentType
    Specifies the type of assignment: Eligible or Active.  Default is Eligible

    .PARAMETER AssignmentExpires
    Specifies the date this assignment expires.  Default is no expiration

    .EXAMPLE
    New-MSPIMDirectoryRoleAssignment -RoleName 'Security Reader' -Id myuser@microsoft.com

    .EXAMPLE
    Import-CSV UserRevocation.csv | New-MSPIMDirectoryRoleAssignments -RoleName 'Security Reader'

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http#example-1-administrator-assigns-user-to-a-role
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [CmdletBinding()]
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
            HelpMessage = 'Type of assignment: Active or Eligible')]
        [ValidateSet(
            'Active',
            'Eligible')]
        [string]$AssignmentType = 'Eligible',

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Date role assignment expires')]
        [string]$AssignmentExpires,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Additional information for assignment')]
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

        $Now = Get-Date
    }

    process
    {
        try
        {
            $null = [System.Guid]::New($id)
            $SubjectId = Get-MSGObjectById -Id $id -Filter "`$select=id"
            if ($SubjectId.'@odata.type' -match '#microsoft.graph.servicePrincipal')
            {
                $AssignmentType = 'Active'
            }
            $SubjectId = $SubjectId.id
        }
        catch
        {
            $SubjectId = (Get-MSGUser -Id $id).id
        }

        if ($null -eq $SubjectId)
        {
            return $SubjectId 
        }

        if (-not [string]::IsNullOrEmpty($AssignmentExpires))
        {
            $AssignmentExpires = ([datetime]$AssignmentExpires).ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        $schedule = [PSCustomObject][Ordered]@{
            type          = 'Once'
            startDateTime = $Now.ToString('yyyy-MM-ddTHH:mm:ssZ')
            endDateTime   = $null
        }

        # Add expiration date if required, otherwise a null entry == permanent assignment

        if (-not [string]::IsNullOrEmpty($AssignmentExpires))
        {
            $schedule.endDateTime = ([datetime]$AssignmentExpires).ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        $roleRequest = [PSCustomObject][Ordered]@{
            roleDefinitionId = $roleId
            resourceId       = $MSGAuthInfo.TenantId
            subjectId        = $SubjectId.id
            assignmentState  = $AssignmentType
            type             = 'AdminAdd'
            reason           = $Reason
            schedule         = $schedule
        }

        if ($PSCmdlet.ShouldProcess("$Id", 'Create PIM directory role assignment'))
        {
            Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/aadroles/roleAssignmentRequests' -Method POST -Body $roleRequest -ObjectName 'MSPIM'
        }
    }
}
