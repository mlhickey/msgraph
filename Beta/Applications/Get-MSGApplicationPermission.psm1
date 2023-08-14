
#region AppPermHelpers
$oauthPermissionTable = @{}
$appPermissionTable = @{}
$resourceAppidToName = @{}
function BuildPermissionTable
{
    param(
        [Parameter(Mandatory = $True)]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $True)]
        [object]$Roles,

        [Parameter(Mandatory = $True)]
        [hashtable]$Table
    )
    $perm = @{}
    if (-not $Table.ContainsKey($AppId))
    {
        $Roles | Select-Object Id, Value | ForEach-Object { $perm.Add($_.Id, $_.value) }
        try
        {
            $Table.Add($AppId, $perm)
        }
        catch
        {
            Write-Warning "AddPermissionTable: Failed to add perms to ${appId}"; return $null
        }
    }
}
function GetPermissionList
{
    param(
        [Parameter(Mandatory = $True)]
        [ValidateSet(
            'Role',
            'Scope')]
        [string]$PermType,

        [Parameter(Mandatory = $True)]
        [object]$resource
    )

    switch ($PermType)
    {
        'Role'
        {
            $Table = $appPermissionTable
            $RoleProperty = 'AppRoles'
        }
        'Scope'
        {
            $Table = $oauthPermissionTable
            $RoleProperty = 'publishedPermissionScopes'
        }
        default
        {
            return $null
        }
    }
    #
    # Need to handle old portal case where they collapsed Role and Scope into a comma-separated value
    #
    $resourceList = ($resource.ResourceAccess.Where( { $_.Type -eq $PermType -or $_.Type -eq 'Role,Scope' }))
    #
    # Create list of names, join final set with "|"
    #
    $plist = @()
    foreach ($perm in $resourceList)
    {
        $plist += (GetPermissionName -AppId $resource.ResourceAppId -PermId $perm.Id -Table $Table -RoleProperty $RoleProperty)
    }
    if ($plist.Count -gt 0)
    {
        ($plist -join '|')
    }
    else
    {
        'None'
    }
}
function GetPermissionName
{
    param(
        [Parameter(Mandatory = $True)]
        [hashtable]$Table,

        [Parameter(Mandatory = $True)]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $True)]
        [string]$PermId,

        [Parameter(Mandatory = $True)]
        [string]$RoleProperty
    )

    if (-not $Table.ContainsKey($AppId))
    {
        try
        {
            $sp = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type servicePrincipals -Filter "Appid eq '$AppId'"
        }
        catch
        {
            $sp = $null
        }

        if ($null -eq $sp.Id)
        {
            return 'unresolved'
        }
        if (-not $resourceAppidToName.Contains($AppId))
        {
            $resourceAppidToName.Add($AppId, $sp.displayName)
        }
        BuildPermissionTable -AppId $AppId -Roles $sp.$RoleProperty -Table $Table
    }
    $permList = $Table.Item($AppId)
    $permList.Item($PermId)
}
function GetResourceName
{
    param(
        [Parameter(Mandatory = $True)]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId
    )
    if (-not $resourceAppidToName.Contains($AppId))
    {
        $sp = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type servicePrincipals -Filter "Appid eq '$AppId'"
        $resourceAppidToName.Add($AppId, $sp.displayName)
    }
    $resourceAppidToName[$AppId]
}

function GetAppConsentedPermissions
{
    param(
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId
    )

    $resId = (Get-MSGServicePrincipal -AppId $AppId).Id

    $list = @(Get-MSGServicePrincipalAppRoleAssignment -Id $Id | Where-Object { $_.resourceId -eq $resId } | Select-Object -Unique appRoleName).appRoleName
    if ($list.Count -gt 0)
    {
        ($list -join '|')
    }
    else
    {
        $null
    }
}
function GetConsentedPermissions
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param(
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId
    )

    $resource = @((Get-MSGServicePrincipalOAuth2PermissionGrant -Id $Id) | Where-Object { $_.consentType -eq 'AllPrincipals' -and $_.resourceId -eq "$AppId" }) | Select-Object -Unique resourceId, scope
    if (-not [string]::IsNullOrEmpty($resource.scope))
    {
        ($resource.scope.Replace(' ', '|'))
    }
    else
    {
        $null
    }
}
function GetCredentialExpiration
{
    param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [object[]]$cObjects
    )

    $today = Get-Date
    $expiresOn = $cObjects[0].endDateTime

    foreach ($cred in $cObjects)
    {
        if (($cred.endDateTime -le $expiresOn) -or ($cred.startDateTime -gt $today))
        {
            continue
        }
        elseif ($cred.endDateTime -gt $expiresOn)
        {
            $expiresOn = $cred.endDateTime
        }
    }
    [datetime]$expiresOn
}
function ProcessCredentials
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [object]$cObjects
    )

    $propSet = [PSCustomObject][Ordered]@{
        Expiration = 'None'
        Threshold  = 'None'
    }

    $today = Get-Date
    if (-not $cObjects)
    {
        return $propset
    }
    $date = GetCredentialExpiration -cObjects $cObjects

    if ($date -gt $today)
    {
        $delta = ($date - $today)
    }
    if (($date -le $today) -or
        ($date -gt $today -and ($delta.days -lt $MinLifetime -or $delta.days -gt $MaxLifetime)))
    {

        if ($delta.days -gt $MaxLifetime)
        {
            $propSet.Expiration = 'ThresholdExceeded'
            $propSet.Threshold = $delta.days
        }
        else
        {
            $propSet.Expiration = $date
            $propSet.Threshold = 'None'
        }
    }
    ($propSet)
}
function GetOwnerList
{
    <#
        Retrieves the owner(s) associated with an application based on its ObjectId

        Accepts:
            ObjectId   -   ObjectId of the applications

        Returns:
            String array of owners
    #>
    param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id
    )
    # Get registered application owners

    $owners = $null
    $owners = @(Get-MSGApplicationOwner -Id $Id -Properties userPrincipalName, displayName -ErrorAction Continue)

    $ownerList = @()
    $upnList = @()
    if ($owners.Count -gt 0)
    {
        foreach ($o in $owners)
        {
            $ownerList += $o.displayName
            $upnList += $o.userPrincipalName
        }
        $ownerList = $ownerList -join '|'
        $upnList = $upnList -join '|'
    }
    else
    {
        $ownerList = 'None'
        $upnList = 'None'
    }
    $ownerObject = @{
        OwnerList = $ownerList
        upnList   = $upnList
    }
    ($ownerObject)
}
function GetApplicationAssignmentList
{
    <#
        Retrieves the list of roles consented to the application. We need to go to Graph for this as PS doesn't return the
        AppRoles field and the other role results are contents of the manifest and do not necessarily match the consented
        permissions

        Accepts:
            ObjectId   -   ObjectId of the service principal

        Returns:
            List of application assignments
    #>
    param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id
    )

    $val = @()
    $ret = @(Get-MSGServicePrincipalAppRoleAssignment -Id $Id)
    if (-not [string]::IsNullOrEmpty($ret))
    {
        $val += ($ret | Select-Object resourceId -Unique).resourceId
    }
    $ret = @(Get-MSGServicePrincipalOAuth2PermissionGrant -Id $Id -OnlyAdminConsented)
    if ($null -ne $ret)
    {
        $val += ($ret | Select-Object resourceId -Unique).resourceId
    }
    ($val)
}
#endregion AppPermHelpers
function Get-MSGApplicationPermission
{
    <#
    .SYNOPSIS
    Get permissions associated with the specified application information

    .DESCRIPTION
    The Get-MSGApplicationPermission cmdlet returns information based on the provided application data.  Applications can be queried based on ObjectId, AppId or SearchString.
    The returned information includes the state of authentication information for symmetric and asymmetric key types, i.e. clientsecret and certificate

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .PARAMETER SearchString
    Specifies a search string.  Performs match based on startsWith(displayName, SearchString)

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER All
    If true, return all applications. If false, return the number of objects specified by the Top parameter

    .PARAMETER Consented
    Include roles only if they've been consented

    .EXAMPLE
    Get-MSGApplicationPermission -SearchString "__MDS"

    AppName AppOwnerList ResourceName                   AppPermissions DelegatedPermissions
    ------- ------------ ------------                   -------------- --------------------
    __MDS__ None         Windows Azure Active Directory

    .EXAMPLE
    Get-MSGApplicationPermission -AppId 375a9d9e-9fc3-4bcd-b24b-77c29e26ff10

    AppName                   AppOwnerList ResourceName                   AppPermissions     DelegatedPermissions
    -------                   ------------ ------------                   --------------     --------------------
    Reporting API Application None         Windows Azure Active Directory Directory.Read.All User.Read

    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'AppId',
            HelpMessage = 'AppId of the application')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ObjectId',
            ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'SearchString',
            HelpMessage = 'Partial/complete displayname of the applications.')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'SearchString')]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'SearchString')]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [switch]$Consented
    )
    #region auth
    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $propSet = "`$select=id,appId,passwordCredentials,keyCredentials,displayName,createdDateTime,RequiredResourceAccess"
        if (-not $All)
        {
            $propSet = "`$top=$top&$propset"
        }
    }
    #endregion auth
    process
    {
        $Error.Clear()
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'appid'
            {
                $allAzureApplications = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type applications -Filter "Appid eq '$AppId'&$propSet"
                break
            }
            'objectid'
            {
                $allAzureApplications = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type applications -Filter "id eq '$Id'&$propset"
                break
            }
            'searchstring'
            {
                $allAzureApplications = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type applications -SearchString "startswith(displayName,'$SearchString')" -Filter $propSet -All:$All
                break
            }
            'topall'
            {
                $allAzureApplications = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type applications -Filter $propSet -All:$All
            }
        }

        foreach ($application in $allAzureApplications)
        {
            #
            # See if we have any work to do
            if ($null -eq $application.Id)
            {
                continue
            }

            $RequiredResourceAccess = $application.RequiredResourceAccess
            if ($RequiredResourceAccess.Count -eq 0)
            {
                Write-Verbose "No required resources, skipping $($application.displayName) - $($application.appId) "
                continue
            }

            $assignmentList = @()
            $associatedServicePrincipal = Get-MSGServicePrincipal -AppId $application.appId
            if ($null -eq $associatedServicePrincipal -or $null -eq $associatedServicePrincipal.Id)
            {
                $assignmentList = $null
            }
            else
            {
                $assignmentList = @(GetApplicationAssignmentList -Id $associatedServicePrincipal.Id)
            }
            # If we're only looking for consented applications and there isn't an assignment list then we're done
            if ($Consented -and $null -eq $assignmentList)
            {
                continue
            }

            $owners = GetOwnerList -Id $application.Id
            $appObjectProperties = [PSCustomObject][Ordered]@{
                PSTypeName                 = 'MSGraph.AppPermissions'
                DisplayName                = $application.displayName
                AppId                      = $application.appId
                CreationDate               = $application.createdDateTime
                OwnerList                  = $owners.upnList
                ResourceList               = @()
                AppSecretExpiration        = 'None'
                AppKeyCredentialExpiration = 'None'
                SPSecretExpiration         = 'None'
                SPKeyCredentialExpiration  = 'None'
            }
            #region Credentials

            if ($application.PasswordCredentials)
            {
                $result = GetCredentialExpiration -cObjects $application.PasswordCredentials
                $appObjectProperties.AppSecretExpiration = $result
            }

            if ($application.KeyCredentials)
            {
                $result = GetCredentialExpiration -cObjects $application.KeyCredentials
                $appObjectProperties.AppKeyCredentialExpiration = $result
            }

            if ($associatedServicePrincipal.PasswordCredentials)
            {
                $result = GetCredentialExpiration -cObjects $associatedServicePrincipal.PasswordCredentials
                $appObjectProperties.SPSecretExpiration = $result
            }

            if ($associatedServicePrincipal.KeyCredentials)
            {
                $result = GetCredentialExpiration -cObjects $associatedServicePrincipal.KeyCredentials
                $appObjectProperties.SPKeyCredentialExpiration = $result
            }
            #endregion Credentials

            foreach ($resource in $RequiredResourceAccess)
            {
                $appPermission = $null
                $userPermission = $null
                $resourceSP = Get-MSGServicePrincipal -AppId $resource.ResourceAppId

                if ($null -ne $assignmentList -and $assignmentList.Contains($resourceSP.id))
                {
                    if ($Consented)
                    {
                        $appPermission = GetAppConsentedPermissions -Id $associatedServicePrincipal.Id -AppId $resource.ResourceAppId
                        $userPermission = GetConsentedPermissions -Id $associatedServicePrincipal.Id -AppId $resourceSP.id
                    }
                    else
                    {
                        $appPermission = GetPermissionList -resource $resource -PermType 'Role'
                        $userPermission = GetPermissionList -resource $resource -PermType 'Scope'
                    }
                }
                $resourceName = GetResourceName -AppId $resource.ResourceAppId
                if ($Consented -and ($null -eq $appPermission -and $null -eq $userPermission))
                {
                    Write-Verbose "$($application.displayName) has no consented permissions, skipping"
                    continue
                }
                $resInfo = [PSCustomObject][Ordered]@{
                    ResourceName         = $resourceName
                    ResourceAppId        = $resource.ResourceAppId
                    AppPermissions       = $appPermission
                    DelegatedPermissions = $userPermission
                }
                $appObjectProperties.ResourceList += $resInfo
            }
            $appObjectProperties
        }
    }
}

