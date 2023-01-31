function Get-MSPIMResourceRoleAssignmentRequest
{
    <#
    .SYNOPSIS
    Get current list of role assignments

    .DESCRIPTION
    The Get-MSPIMResourceRoleAssignmentRequest cmdlet returns the current list of resource requests for the specified user

    .PARAMETER Id
    Specifies the user id to query for assignment requests

    .PARAMETER ResourceId
    Specifies the resource to query for assignment requests

    .EXAMPLE
    Get-MSPIMResourceRoleAssignmentRequest -MyUser

    Id                                   ResourceId                           RoleDefinitionId                     SubjectId                            RequestedDateTime      Status
    --                                   ----------                           ----------------                     ---------                            -----------------      ------
    886703EB-1CFC-474E-8356-9891527355D9 419098bd-9906-4fc2-a65a-3d5cc42be01e 5cfeee3a-e63f-4ea3-9909-90c759e5dead f839606d-4143-4ed4-a049-56c26049a343 2018-01-30T21:01:50.3Z Closed

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
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
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
                $filter = "subjectId eq '$SubjectId'"
                break
            }
            "user"
            {
                $SubjectId = (Get-MSGObject -Type "users/$id" -Filter "`$select=id").Id
                if ($null -eq $SubjectId)
                {
                    Write-Error "Can't resovel $id to user"
                    return $null
                }
                $filter = "subjectId eq '$SubjectId'"
                break
            }
        }

        Get-MSGObject -Type "privilegedAccess/azureResources/roleAssignmentRequests" -Filter $filter -ObjectName "MSPIM"
    }
}
