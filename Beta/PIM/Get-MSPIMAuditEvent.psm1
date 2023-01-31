function Get-MSPIMAuditEvent
{
    <#
    .SYNOPSIS
    Get PIM audit entries

    .DESCRIPTION
    The Get-MSPIMAuditEvent cmdlet returns the audit events associated with the specified parameters
    This PIM team has retired their dedicated endpoint in favor of consolidated
    Azure AD audit logs.  This cmdlet is a wrapper for the Get-MSGAuditEvent cmdlet

    .PARAMETER Id
    .PARAMETER UserPrincipalName
    .PARAMETER ObjectId
    Specifies the ID of a user in Azure AD

    .PARAMETER RoleName
    Specifies the particular Azure role name to filter on (client-side filtering only)

    .PARAMETER RoleId
    Specifies the particular Azure role id to filter on (client-side filtering only)

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER All
    Return all events for provided parameters

    .EXAMPLE
    Get-MSPIMAuditEvent -RequestType Activate -top 5

    RoleId                               RoleName                  RequestorId                          RequestorName                 RequestType CreationDateTime
    ------                               --------                  -----------                          -------------                 ----------- ----------------
    fasdasdd-1234-5a4b-c9ad-3fcba4d0a4de Application Administrator 56e0351e-473d-4da4-8b14-2b88366f7421 A User                        Activate    2019-06-05T21:30:10.6701793Z
    fasdasdd-1234-5a4b-c9ad-3fcba4d0a4de User Administrator        56e0351e-473d-4da4-8b14-2b88366f7421 A User                        Activate    2019-06-05T21:27:40.6369106Z
    fasdasdd-1234-5a4b-c9ad-3fcba4d0a4da Global Administrator      34621156-66c2-4d45-bbde-d3591c42e861 An Admin                      Activate    2019-06-05T21:17:49.252548Z
    fasdasdd-1234-5a4b-c9ad-3fcba4d0a4db Security Administrator    83a24c6e-c699-4504-95c7-7eea90d2465a Another User                  Activate    2019-06-05T21:14:04.3327767Z
    fasdasdd-1234-5a4b-c9ad-3fcba4d0a4da Global Administrator      d54523e5-cac3-4067-ab1c-854a31cf63db Another Admin                 Activate    2019-06-05T21:12:51.6885253Z

    .LINK
    https://docs.microsoft.com/en-us/graph/api/privilegedoperationevent-list?view=graph-rest-beta

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = "Common")]
    param(
        [Parameter(ParameterSetName = "Common")]
        [Parameter(ParameterSetName = "RoleName")]
        [Parameter(ParameterSetName = "RoleId")]
        [ValidateSet(
            "Add member to role completed (PIM activation)",
            "Add member to role requested (PIM activation)",
            "Remove member from role (PIM activation expired)",
            "Add eligible member to role in PIM completed (timebound)",
            "Add eligible member to role in PIM requested (renew)",
            "Remove member from role completed (PIM deactivate)",
            "Remove member from role requested (PIM deactivate)",
            "Remove permanent eligible role assignment",
            "Remove eligible member from role in PIM completed (timebound)",
            "Offboarded resource from PIM",
            "Add eligible member to role in PIM completed (permanent)",
            "Add eligible member to role in PIM requested (permanent)",
            "Add member to role in PIM completed (timebound)",
            "Add member to role in PIM requested (timebound)",
            "Process request",
            "Process role update request",
            "Resolve PIM alert",
            "Remove eligible member from role in PIM requested (timebound)",
            "Remove eligible member from role in PIM completed (permanent)",
            "Remove eligible member from role in PIM requested (permanent)",
            "Remove member from role in PIM completed (permanent)",
            "Remove member from role in PIM requested (permanent)",
            "Remove member from role in PIM completed (timebound)",
            "Add eligible member to role in PIM requested (timebound)"
        )]
        [string]$RequestType,

        [Parameter(ParameterSetName = "RoleId",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "GUID of PIM role")]
        [Alias("RoleDefinitionId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$RoleID,

        [Parameter(ParameterSetName = "Common",
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [Parameter(ParameterSetName = "RoleName")]
        [Parameter(ParameterSetName = "RoleId")]
        [ValidateNotNullOrEmpty()]
        [Alias("ObjectId", "UserPrincipalName")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(ParameterSetName = "Common",
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [Parameter(ParameterSetName = "RoleName")]
        [Parameter(ParameterSetName = "RoleId")]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(ParameterSetName = "Common",
            Mandatory = $False)]
        [Parameter(ParameterSetName = "RoleName")]
        [Parameter(ParameterSetName = "RoleId")]
        [datetime]$StartDate = (Get-Date).AddDays(-30),

        [Parameter(ParameterSetName = "Common",
            Mandatory = $False)]
        [Parameter(ParameterSetName = "RoleName")]
        [Parameter(ParameterSetName = "RoleId")]
        [datetime]$EndDate = (Get-Date),

        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
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
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {
        [string[]]$filterList = $null
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "rolename"
            {
                $RoleName = $PSBoundParameters['RoleName']
                $roleId = $roleName2Id.Item($RoleName)
                $filterList += "roleId eq '${roleId}'"
                break
            }
            "roleid"
            {
                try { $null = $roleId2Name.Item($RoleID) }
                catch { Write-Error "$roleId is not currently in the list of supported PIM roles"; return $null }
                $filterList += "roleId eq '${roleId}'"
                break
            }
        }

        $auditParams = @{}
        $auditParams.Add("LoggedByService", "PIM")
        $auditParams.Add("Category", "RoleManagement")

        if (-not [string]::IsNullOrEmpty($Id))
        {
            if ($id.IndexOf("@" -gt 0))
            {
                $auditParams.Add("InitiatedByUserPrincipalName", $id)
            }
            else
            {
                $auditParams.Add("InitiatedByuserid", $id)
            }
        }
        elseif (-not [string]::IsNullOrEmpty($DisplayName))
        {
            $auditParams.Add("InitiatedByUserDisplayName", $DisplayName)
        }

        if (-not [string]::IsNullOrEmpty($RequestType))
        {
            $auditParams.Add("ActivityDisplayName", $RequestType)
        }

        if (-not [string]::IsNullOrEmpty($startDate))
        {
            $auditParams.Add("StartDate", $startDate)
        }
        if (-not [string]::IsNullOrEmpty($EndDate))
        {
            if ([string]::IsNullOrEmpty($StartDate)) { throw "EndDate specified with no StarDate" }
            $auditParams.Add("EndDate", $endDate)
        }

        if (-not [string]::IsNullOrEmpty($roleId))
        {
            $auditParams.Add("TargetResourceId", $roleId)
        }

        if ($All.IsPresent) { $auditParams.Add("All", $All) } else { $auditParams.Add("Top", $Top) }
        Get-MSGAuditLogDirectoryEntries @auditParams
    }
}
