function Get-MSGApplicationAssignedPolicy
{
    <#
    .SYNOPSIS
    Retrieve the policy objects assigned to an application

    .DESCRIPTION
    tHE function Get-MSGApplicationAssignedPolicy returns the polocies associated with the specified application object ID.

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Type
    Specifies the type of policy to retrieve - TokenLifeTime or TokenIssuance

    .LINK
    https://docs.microsoft.com/en-us/graph/api/policy-list-assigned?view=graph-rest-beta

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the application")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Policy type: TokenLifetime or TokenIssuance")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("TokenLifetime", "TokenIssuance")]
        [string]$PolicyType = "TokenLifetime"
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
        $type = "{0}Policies" -f (camelCase $PolicyType)
        $res = Get-MSGObject -Type "applications/$Id/$type"
        if ($res.StatusCode -ge 400) { return $res }
        $res.appRoleAssignments
    }
}
