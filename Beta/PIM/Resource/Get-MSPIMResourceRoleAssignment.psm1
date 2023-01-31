function Get-MSPIMResourceRoleAssignment
{
    <#
    .SYNOPSIS
    Get current list of role assignments

    .DESCRIPTION
    The Get-MSPIMResourceRoleAssignment cmdlet returns the current list of resources for the specified user

    .EXAMPLE
    Get-MSPIMResourceRoleAssignment  -My

    Id                                   ResourceId                           RoleDefinitionId                     MemberType AssignmentState Status
    --                                   ----------                           ----------------                     ---------- --------------- ------
    6c67b7cd-ac99-4e45-9c0d-f4bea478f2b0 6f8a626a-aa31-4017-aed8-580c09a59e58 410c13f8-3f6f-476e-9dd6-f2ba942a6c75 Direct     Active          Accepted
    00000000-0000-0000-0000-000000000000 c1a8072e-bbeb-4561-a9dc-5e2f140e5326 bf07e1a8-a456-4782-afd0-244635d6f297 Group      Active          Accepted

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceresource-list?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = "my")]
    param(

        [Parameter(Mandatory = $false,
            ParameterSetName = "User",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "ResourceId",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the specific resource")]
        [string]$ResourceId,

        [Parameter(Mandatory = $false,
            ParameterSetName = "My")]
        [switch]$MyUser
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "resourceid"
            {
                $filter = "resourceId eq '$ResourceId'"
                break
            }
            "my"
            {
                $SubjectId = (Get-MSGObject -Type "me" -Filter "`$select=id").Id
                $filter = "`$expand=linkedEligibleRoleAssignment,subject,roleDefinition(`$expand=resource)&`$filter=(subjectId eq '$SubjectId')"
                break
            }
            "user"
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

                if ($null -eq $SubjectId)
                {
                    Write-Error "Can't resovel $id to object"
                    return $null
                }
                $filter = "`$expand=linkedEligibleRoleAssignment,subject,roleDefinition(`$expand=resource)&`$filter=(subjectId eq '$SubjectId')"
                break
            }
        }

        $res = Get-MSGObject -Type "privilegedAccess/azureResources/roleAssignments" -Filter $filter

        if ($res.StatusCode -ge 400) { return $res }
        $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, "MSPIM.privilegedAccess.roleAssignments") }
        $res
    }
}
