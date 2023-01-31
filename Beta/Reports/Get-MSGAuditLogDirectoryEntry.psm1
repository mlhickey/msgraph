$script:auditLogTable = @{
    'Category'                        = "category eq 'FARG'"
    'ActivityDisplayName'             = "activityDisplayName eq 'FARG'"
    'LoggedByService'                 = "loggedByService eq 'FARG'"
    'InitiatedByuserid'               = "initiatedBy/user/id eq 'FARG'"
    'InitiatedByUserDisplayName'      = "initiatedBy/user/displayName eq 'FARG'"
    'InitiatedByUserPrincipalName'    = "initiatedBy/user/userPrincipalName eq 'FARG'"
    'InitiatedByAppAppId'             = "initiatedBy/app/appId eq 'FARG'"
    'InitiatedByAppAppDisplayName'    = "initiatedBy/app/appDisplayName eq 'FARG'"
    'TargetResourceId'                = "targetResources/any(t: t/id eq 'FARG')"
    'TargetResourceDisplayName'       = "targetResources/any(t:t/displayName eq 'FARG')"
    'TargetResourceUserPrincipalName' = "targetResources/any(t:t/userPrincipalName eq 'FARG')"
    'StartDate'                       = "FARG"
    'EndDate'                         = "FARG"
}
function Get-MSGAuditLogDirectoryEntry
{
    <#
    .SYNOPSIS
    Retrieve Azure AD audit logs

    .DESCRIPTION
    Azure Active Directory (Azure AD) tracks user activity and sign-in metrics and creates audit log reports that help you understand how your users access and leverage Azure AD services.

    .EXAMPLE
    Get-MSGAuditLogDirectoryEntry -StartDate 2018-06-24 -EndDate 7-23-2018 -Verbose

    .EXAMPLE
    Get-MSGAuditLogDirectoryEntry -TargetResourceId e1c5fca6-b39b-4df0-9acb-f067196bf4fd -Verbose

    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/resources/azure_ad_auditlog_overview
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectUsageOfAssignmentOperator', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Top = 100,

        [Parameter(Mandatory = $false)]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 360)]
        [int]$RetentionPeriod = 30,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveIds
    )

    dynamicparam
    {
        $paramTable = $auditLogTable
        $dateParam = "activityDateTime"
        $auditType = "directoryAudits"
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        foreach ($paramName in $paramTable.GetEnumerator())
        {
            New-DynamicParam -Name $paramName.Name -DPDictionary $Dictionary
        }
        $Dictionary
    }

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }

        $today = (Get-Date)

        if ($null -ne $PSBoundParameters['StartDate'])
        {
            $StartDate = [datetime]$PSBoundParameters['StartDate']
            [void]$PSBoundParameters.Remove('StartDate')
        }

        if ($null -ne $PSBoundParameters['EndDate'])
        {
            $EndDate = [datetime]$PSBoundParameters['EndDate']
            [void]$PSBoundParameters.Remove('EndDate')
        }

        if ($StartDate -and ($delta = ($today - $StartDate).days) -gt $RetentionPeriod)
        {
            $delta -= $RetentionPeriod
            throw "$StartDate is $delta days outside the $RetentionPeriod day retention period"
        }
    }

    process
    {
        $queryFilter = @()
        #region DateProcessing
        if ($EndDate -and ($StartDate -gt $EndDate))
        {
            throw "StarDate is greater than EndDate"
        }
        if ($StartDate -and $EndDate)
        {
            # Have a range to build
            $queryFilter += "$dateParam ge $($StartDate.ToString('yyyy-MM-dd')) and $dateParam le $($EndDate.ToString('yyyy-MM-dd'))"
        }
        elseif ($StartDate)
        {
            $queryFilter += "$dateParam ge $($StartDate.ToString('yyyy-MM-dd'))"
        }
        elseif ($EndDate)
        {
            $queryFilter += "$dateParam le $($EndDate.ToString('yyyy-MM-dd'))'"
        }

        #endregion DateProcessing
        foreach ($psbp in $PSBoundParameters.GetEnumerator())
        {
            $key = $psbp.Key
            $value = $psbp.value
            if ($paramTable.Contains($key))
            {
                $q = $($paramTable[$key])
                $q = $q.Replace("FARG", $value)
                $queryFilter += $q
            }
        }
        #
        if (-not [string]::IsNullOrEmpty($queryFilter))
        {
            [string]$filter = "(" + ($queryFilter -join ' and ') + ")"
        }
        if (-not $All -and $Top)
        {
            if ($filter)
            {
                $filter += "&"
            }
            $filter += "`$top=$top"
        }

        $res = Get-MSGObject -Type "auditLogs/$auditType" -Filter $Filter -All:$All
        if ($res.StatusCode -ge 400) { return $res }
        if ($ResolveIds.IsPresent)
        {
            $count = 0;
            foreach ($r in $res)
            {
                if ($r.StatusCode -ge 400) { Write-Warning "Count: $count`nRecord: $r"; continue }
                try { New-ReportRecord -record $r; $count++ }
                catch { Write-Error "$_ : $r"; continue }
            }
        }
        else { $res }
    }
}
