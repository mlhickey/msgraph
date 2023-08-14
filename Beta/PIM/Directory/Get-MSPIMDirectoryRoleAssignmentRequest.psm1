function Get-MSPIMDirectoryRoleAssignmentRequest
{
    <#
    .SYNOPSIS
    Get current PIM assignment requests

    .DESCRIPTION
    The Get-MSPIMDirectoryRoleAssignmentRequest cmdlet returns current PIM role assignment requests

    .PARAMETER My
    Uses current authenticated user context (Default)

    .PARAMETER Id
    .PARAMETER UserPrincipalName
    .PARAMETER ObjectId
    Specifies the ID of a user in Azure AD

    .PARAMETER RoleName
    Specifies the particular Azure role name to return.

    .PARAMETER RoleId
    Specifies the particular Azure role id to return

    .PARAMETER All
    Return all role assignments

    .EXAMPLE
    Get-MSPIMDirectoryRoleAssignmentRequest -My

    RoleDefinitionId                     SubjectId                            Reason                          Status
    ----------------                     ---------                            ------                          ------
    3f89ad0c-f3bd-46f7-a341-f995497e1e48 f839606d-4143-4ed4-a049-56c26049a343 graph module update development Closed
    3f89ad0c-f3bd-46f7-a341-f995497e1e48 f839606d-4143-4ed4-a049-56c26049a343 Testing new codebase            Closed
    3f89ad0c-f3bd-46f7-a341-f995497e1e48 f839606d-4143-4ed4-a049-56c26049a343 Deactivation request            Closed
    .
    .
    .
    .LINK
    - https://docs.microsoft.com/en-us/graph/api/privilegedroleassignmentrequest-list?view=graph-rest-beta&tabs=cs

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding(DefaultParameterSetName = 'My')]
    param(
        [Parameter(ParameterSetName = 'My',
            HelpMessage = 'My roles')]
        [switch]$My,

        [Parameter(ParameterSetName = 'RoleId',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GUID of PIM role to enable')]
        [Parameter(ParameterSetName = 'My')]
        [Parameter(ParameterSetName = 'User')]
        [Alias('RoleDefinitionId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$RoleID,

        [Parameter(ParameterSetName = 'User',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the user.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(Mandatory = $false)]
        [switch]$All
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
        $formatstring = "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleAssignmentRequests"
    }

    process
    {
        [string[]]$filterList
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'my'
            {
                $Id = (Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'me' -Filter "`$select=id").Id
                $filterList += "subjectId eq '${id}'"
                break
            }
            'user'
            {
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
                $filterList += "subjectId eq '${SubjectId}'"
                break
            }
            'rolename'
            {
                $RoleName = $PSBoundParameters['RoleName']
                $roleId = $global:roleName2Id.Item($RoleName)
                $filterList += "roleDefinitionId eq '${roleId}'"
                break
            }
            'roleid'
            {
                $filterList += "roleDefinitionId eq '${roleId}'"
                break
            }
        }

        if ($filterList.Count -gt 0)
        {
            $arglist = $filterList -join ' and '
            $filter = "${arglist}"
        }
        # Added expansion
        #$filter = "`$expand=linkedEligibleRoleAssignment,roleDefinition,subject&`$count=true&`$filter=$filter"
        if (-not $All)
        {
            $filter = @($filter, "`$top=$top") -join '&'
        }

        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $formatstring -Filter $filter -All:$All -ObjectName 'MSPIM'
        if ($null -ne $res -and $res.StatusCode -lt 300)
        {
            $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, 'MSPIM.privilegedAccess.roleAssignmentRequests') }
        }
        $res
    }
}

