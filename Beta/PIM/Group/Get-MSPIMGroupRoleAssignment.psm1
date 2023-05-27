function Get-MSPIMGroupRoleAssignment
{
    <#
    .SYNOPSIS
    Get current list of role assignments

    .DESCRIPTION
    The Get-MSPIMGroupRoleAssignment cmdlet returns the current list of Groups for the specified user

    .EXAMPLE
    Get-MSPIMGroupRoleAssignment  -My

    Id                                   GroupId                           RoleDefinitionId                     MemberType AssignmentState Status
    --                                   ----------                           ----------------                     ---------- --------------- ------
    6c67b7cd-ac99-4e45-9c0d-f4bea478f2b0 6f8a626a-aa31-4017-aed8-580c09a59e58 410c13f8-3f6f-476e-9dd6-f2ba942a6c75 Direct     Active          Accepted
    00000000-0000-0000-0000-000000000000 c1a8072e-bbeb-4561-a9dc-5e2f140e5326 bf07e1a8-a456-4782-afd0-244635d6f297 Group      Active          Accepted

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceGroup-list?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'my')]
    param(

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the group.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'GroupId',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the specific Group')]
        [string]$GroupId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'My')]
        [switch]$MyUser
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

        $filter = "`$expand=linkedEligibleRoleAssignment,subject,roleDefinition(`$expand=resource)&`$filter=(roleDefinition/resource/id eq '$id')"

        $res = Get-MSGObject -Type 'privilegedAccess/aadGroups/roleAssignments' -Filter $filter

        if ($res.StatusCode -ge 400)
        {
            return $res
        }
        $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, 'MSPIM.privilegedAccess.roleAssignments') }
        $res
    }
}
