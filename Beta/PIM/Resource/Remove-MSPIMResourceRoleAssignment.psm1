function Remove-MSPIMResourceRoleAssignment
{
    <#
    .SYNOPSIS
    Get current PIM assignments

    .DESCRIPTION
    The Remove-MSPIMResourceRoleAssignments cmdlet removes the speciifed PIM role assignment from the specified user

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER ResourceId
    Specified the resourceid being assigned

    .PARAMETER RoleId
    Specifies the particular Azure role id to return

    .EXAMPLE
    Remove-MSPIMResourceRoleAssignment -RoleID e668ca4b-b5b4-48ba-96ee-31840527b001 -ResourceId dc531c43-5a78-4617-b60d-9fe8c575c3d4 -Id dfb101d4-e499-49ff-a91d-c48555bb2232

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceroleassignmentrequest-post?view=graph-rest-beta&tabs=http#example-4-administrator-removes-user-from-a-role
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "GUID of PIM role to enable")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [Alias("RoleDefinitionId")]
        [string]$RoleID,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [ValidateNotNullOrEmpty()]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the resource being assigned")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$ResourceId,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [ValidateSet(
            "Permanent",
            "Eligible")]
        [string]$AssignmentType = "Eligible"
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
        if ([string]::IsNullOrEmpty($RoleID))
        {
            Write-Error "You must supply a PIM role name or id"
            return $null
        }

        $subjectId = (Get-MSGObject -Type "users/$id" -Filter "`$select=id").Id

        $body = [PSCustomObject][Ordered]@{
            assignmentState  = $AssignmentType
            #linkedEligibleRoleAssignmentId = $null
            resourceId       = $ResourceId
            roleDefinitionId = $RoleID
            subjectId        = $SubjectId
            type             = "AdminRemove"
        }

        if ($PSCmdlet.ShouldProcess("$Id", "Remove resource assignment"))
        {
            Set-MSGObject -Type "privilegedAccess/azureResources/roleAssignmentRequests" -Method POST -Body $body -ObjectName "MSPIM"
        }
    }
}
