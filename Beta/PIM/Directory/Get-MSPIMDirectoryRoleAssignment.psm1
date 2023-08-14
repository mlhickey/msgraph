function Get-MSPIMDirectoryRoleAssignment
{
    <#
    .SYNOPSIS
    Get current PIM assignments

    .DESCRIPTION
    The Get-MSPIMDirectoryRoleAssignment cmdlet returns current PIM role assignment information

    .PARAMETER My
    Uses current authenticated user context (Default)

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER RoleName
    Specifies the particular Azure role name to return.

    .PARAMETER RoleId
    Specifies the particular Azure role id to return

    .PARAMETER All
    Return all role assignments

    .PARAMETER ResolveIDs
    Resolves the returned GUIDs into human-readable results.  Transforms user objectids to UPNs, role IDs to role names

    .EXAMPLE
    Get-MSPIMDirectoryRoleAssignment -My

    RoleDefinitionId                     SubjectId                            AssignmentState StartDateTime            EndDateTime
    ----------------                     ---------                            --------------- -------------            -----------
    9d480089-e4fe-4f28-b372-a388a2f6e64d f839606d-4143-4ed4-a049-56c26049a343 Eligible        2019-12-06T18:21:29.567Z
    1cae0ceb-d165-4cb7-bc9b-e0394bb02d0a f839606d-4143-4ed4-a049-56c26049a343 Eligible        2019-12-06T18:21:29.873Z
    3f89ad0c-f3bd-46f7-a341-f995497e1e48 f839606d-4143-4ed4-a049-56c26049a343 Eligible        2019-12-06T18:21:30.493Z
    3f89ad0c-f3bd-46f7-a341-f995497e1e48 f839606d-4143-4ed4-a049-56c26049a343 Active          2019-12-11T15:22:13.653Z 2019-12-12T15:22:12.22Z
    6ea15ea3-7772-4850-8360-ca212872d4fe f839606d-4143-4ed4-a049-56c26049a343 Eligible        2019-12-06T18:21:30.78Z

    .EXAMPLE
    Get-MSPIMDirectoryRoleAssignment -Id mhickey@microsoft.com -ResolveIDs

    SubjectId                            UserPrincipalName     DisplayName RoleDefinitionId                     RoleName                              EndDateTime
    ---------                            -----------------     ----------- ----------------                     --------                              -----------
    f839606d-4143-4ed4-a049-56c26049a343 mhickey@microsoft.com Mike Hickey 9d480089-e4fe-4f28-b372-a388a2f6e64d Billing Administrator
    f839606d-4143-4ed4-a049-56c26049a343 mhickey@microsoft.com Mike Hickey 1cae0ceb-d165-4cb7-bc9b-e0394bb02d0a Teams Communications Support Engineer
    f839606d-4143-4ed4-a049-56c26049a343 mhickey@microsoft.com Mike Hickey 3f89ad0c-f3bd-46f7-a341-f995497e1e48 Security Reader
    f839606d-4143-4ed4-a049-56c26049a343 mhickey@microsoft.com Mike Hickey 3f89ad0c-f3bd-46f7-a341-f995497e1e48 Security Reader                       2019-12-12T15:22:12.22Z
    f839606d-4143-4ed4-a049-56c26049a343 mhickey@microsoft.com Mike Hickey 6ea15ea3-7772-4850-8360-ca212872d4fe Reports Reader

    .EXAMPLE
    Get-MSPIMDirectoryRoleAssignment -RoleName 'Search Editor' -ResolveIDs

    SubjectId                            UserPrincipalName      DisplayName            RoleDefinitionId                     RoleName      EndDateTime
    ---------                            -----------------      -----------            ----------------                     --------      -----------
    1a95cd85-5d5d-4a7e-b22c-0793cf09d9f3 coltren@microsoft.com  Colin Trent            abd749de-ee5a-4e98-8027-700e5fc4aedb Search Editor

    .LINK
     - https://docs.microsoft.com/en-us/graph/api/governanceroleassignment-list?view=graph-rest-beta

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = 'My')]
    param(
        [Parameter(ParameterSetName = 'My',
            HelpMessage = 'GUID of PIM role to enable')]
        [switch]$My,

        [Parameter(ParameterSetName = 'RoleId',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GUID of PIM role to enable')]
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

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All',
            HelpMessage = 'Return all role assignments')]
        [switch]$All,

        [Parameter(
            HelpMessage = 'Resolve GUIDs to human-readable format'
        )]
        [switch]$ResolveIDs
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
        $formatstring = "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleAssignments"
    }

    process
    {
        $filter = $null
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'my'
            {
                $SubjectId = (Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'me' -Filter "`$select=id").Id
                $filter = "subjectId eq '$SubjectId'"
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
                $filter = "subjectId eq '$SubjectId'"
                break
            }
            'rolename'
            {
                $RoleName = $PSBoundParameters['RoleName']
                $roleId = $global:roleName2Id.Item($RoleName)
                $filter = "roleDefinitionId eq '$roleId'"
                break
            }
            'roleid'
            {
                $filter = "roleDefinitionId eq '$roleId'"
                break
            }
            'all'
            {
                $formatstring = "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleAssignments"
                break
            }
        }
        # Added expansion
        $optionList = "`$expand=linkedEligibleRoleAssignment,roleDefinition,subject&`$count=true&`$filter=$filter"
        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $formatstring -OptionList $optionList -ObjectName 'MSPIM' -All:$All
        if ($res.StatusCode -ge 400)
        {
            return $res 
        }
        $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, 'MSPIM.privilegedAccess.roleAssignment') }

        if ($ResolveIDs)
        {
            ResolveIds -ObjectList $res
        }
        else
        {
            $res
        }
    }
}
