function New-MSPIMResourceRoleAssignment
{
    <#
    .SYNOPSIS
    Creates a new PIM assignment

    .DESCRIPTION
    The New-MSPIMResourceRoleAssignment cmdlet assigns the speciifed PIM role assignment to the specified user

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER ResourceId
    Specified the resourceid being assigned

    .PARAMETER RoleName
    [tbd] Specifies the particular Azure role name to assign.

    .PARAMETER RoleId
    Specifies the particular Azure role id to assign

    .PARAMETER AssignmentType
    Specifies the type of assignment: Eligible or Permanent.  Default is Eligible

    .PARAMETER AssignmentExpires
    Specifies the date this assignment expires.  Default is one year expiration

    .PARAMETER Reason
    Specifies optional text to assoaciate with the assignment, e.g. rationale, service ticket, etc

    .EXAMPLE
    New-MSPIMDirectoryRoleAssignment -RoleName 'Security Reader' -Id myuser@microsoft.com

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http#example-1-administrator-assigns-user-to-a-role
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GUID of PIM role to enable')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [Alias('RoleDefinitionId')]
        [string]$RoleID,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the user.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the resource being assigned')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$ResourceId,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the user.')]
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
            Write-Error 'You must supply a role id'
            return $null
        }

        $Now = Get-Date
    }

    process
    {
        $SubjectId = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "users/$id" -Filter "`$select=id"

        if ($null -eq $SubjectId)
        {
            return $SubjectId 
        }

        if (-not [string]::IsNullOrEmpty($AssignmentExpires))
        {
            $AssignmentExpires = ([datetime]$AssignmentExpires).ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        if ([string]::IsNullOrEmpty($AssignmentExpires))
        {
            $AssignmentExpires = $Now.AddYears(1).ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        $schedule = [PSCustomObject][Ordered]@{
            type          = 'Once'
            startDateTime = $Now.ToString('yyyy-MM-ddTHH:mm:ssZ')
            endDateTime   = $AssignmentExpires
        }

        $roleRequest = [PSCustomObject][Ordered]@{
            roleDefinitionId = $roleId
            resourceId       = $ResourceId
            subjectId        = $SubjectId
            assignmentState  = $AssignmentType
            type             = 'AdminAdd'
            reason           = $Reason
            schedule         = $schedule
        }

        if ($PSCmdlet.ShouldProcess("$Id", 'Create resource assignment'))
        {
            Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/azureResources/roleAssignmentRequests' -Method POST -Body $roleRequest -ObjectName 'MSPIM'
        }
    }
}
