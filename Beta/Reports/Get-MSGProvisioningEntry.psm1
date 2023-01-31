$script:provisioningTable = @{
    'ActivityDateTime'           = "activityDateTime eq 'FARG'"
    'Tenantid'                   = "tenantid eq 'FARG'"
    'Jobid'                      = "jobid eq 'FARG'"
    'Changeid'                   = "changeid eq 'FARG'"
    'Cycleid'                    = "cycleid eq 'FARG'"
    'Action'                     = "action eq 'FARG'"
    'StatusInfo'                 = "statusInfo/status eq 'FARG'"
    'SourceSystemDisplayName'    = "sourceSystem/displayName eq 'FARG'"
    'TargetSystemDisplayName'    = "targetSystem/displayName eq 'FARG'"
    'SourceIdentityIdentityType' = "sourceIdentity/identityType eq 'FARG'"
    'ServicePrincipalId'         = "servicePrincipal/id eq 'FARG'"
    'ServicePrincipalName'       = "servicePrincipal/name eq 'FARG'"
    'TargetIdentityIdentityType' = "targetIdentity/identityType eq 'FARG'"
    'SourceIdentityId'           = "sourceIdentity/id eq 'FARG'"
    'TargetIdentityId'           = "targetIdentity/id eq 'FARG'"
    'SourceIdentityDisplayName'  = "sourceIdentity/displayName eq 'FARG'"
    'TargetIdentityDisplayName'  = "targetIdentity/displayName eq 'FARG'"
    "initiatedByDisplayName"     = "initiatedBy/displayName eq 'FARG'"
    'StartDate'                  = "FARG"
    'EndDate'                    = "FARG"
}
function Get-MSGProvisioningEntry
{
    <#
    .SYNOPSIS
    Retrieces Azure AD provisioning logs

    .DESCRIPTION
    Azure Active Directory (Azure AD) tracks user activity and sign-in metrics and creates audit log reports that help you understand how your users access and leverage Azure AD services.

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/provisioningobjectsummary?view=graph-rest-beta
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
        [switch]$Raw
    )

    dynamicparam
    {

        $paramTable = $provisioningTable
        $auditType = "provisioning"
        $dateParam = "activityDateTime"
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
                $queryFilter += $($paramTable[$key])
                $queryFilter = $queryFilter.Replace("FARG", $value)
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

        Get-MSGObject -Type "auditLogs/$auditType" -Filter $Filter -All:$All
    }
}
