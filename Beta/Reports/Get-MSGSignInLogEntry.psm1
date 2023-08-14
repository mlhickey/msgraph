$script:signInTable = @{
    'Id'                      = "id eq 'FARG'"
    'UserId'                  = "userId eq 'FARG'"
    'AppId'                   = "appId eq 'FARG'"
    'CreatedDateTime'         = "createdDateTime eq 'FARG'"
    'UserDisplayName'         = "(userId eq 'FARG' or startsWith(userDisplayName, 'FARG'))"
    'UserPrincipalName'       = "startsWith(userPrincipalName, 'FARG')"
    'AppDisplayName'          = "startsWith(appDisplayName, 'FARG')"
    'IpAddress'               = "ipAddress eq 'FARG'"
    'LocationCity'            = "location/city eq 'FARG'"
    'LocationState'           = "location/state eq 'FARG'"
    'LocationCountryOrRegion' = "location/countryOrRegion eq 'FARG'"
    'StatusErrorCode'         = "status/errorCode eq 'FARG'"
    'ClientAppUsed'           = "clientAppUsed eq 'FARG'"
    'ConditionalAccessStatus' = "conditionalAccessStatus eq 'FARG'"
    'Browser'                 = "(deviceDetail/browser eq 'FARG' or startsWith(deviceDetail/browser, 'FARG'))"
    'OperatingSystem'         = "(deviceDetail/operatingSystem eq 'FARG' or startsWith(deviceDetail/operatingSystem, 'FARG'))"
    'CorrelationId'           = "correlationId eq 'FARG'"
    'IsRisky'                 = "isRisky eq 'FARG'"
    'StartDate'               = 'FARG'
    'EndDate'                 = 'FARG'
}
function Get-MSGSignInLogEntry
{
    <#
    .SYNOPSIS
    Retrieve Azure AD SignIn logs

    .DESCRIPTION
    Azure Active Directory (Azure AD) tracks user activity and sign-in metrics and creates audit log reports that help you understand how your users access and leverage Azure AD services.

    .EXAMPLE
    Get-MSGSignInLogEntry -UserPrincipalName mhickey@microsoft.com -Top 5

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/signin?view=graph-rest-beta
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
        $paramTable = $signInTable
        $dateParam = 'createdDateTime'
        $auditType = 'signIns'

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
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
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
            throw 'StarDate is greater than EndDate'
        }
        if ($StartDate -and $EndDate)
        {
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
                $queryFilter = $queryFilter.Replace('FARG', $value)
            }
        }
        #
        if (-not [string]::IsNullOrEmpty($queryFilter))
        {
            [string]$filter = '(' + ($queryFilter -join ' and ') + ')'
        }
        if (-not $All -and $Top)
        {
            if ($filter)
            {
                $filter += '&'
            }
            $filter += "`$top=$top"
        }

        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "auditLogs/$auditType" -Filter $Filter -All:$All
        if ($res.StatusCode -ge 400)
        {
            return $res 
        }
        if ($ResolveIds.IsPresent)
        {
            foreach ($r in $res)
            {
                New-SigninRecord -record $r
            }
        }
        else
        {
            $res 
        }
    }
}
