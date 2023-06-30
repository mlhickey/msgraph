$appPermissionTable = @{}
function Get-MSGServicePrincipalAppRoleAssignment
{
    <#
    .SYNOPSIS
    Get roles assigned to the specifed service principal

    .DESCRIPTION
    The Get-MSGServicePrincipalAppRoleAssignment cmdlet returns the  applications roles assigned to the specified service principal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER ResolveIds
    Resovlve Graph API results

    .EXAMPLE
    Get-MSGServicePrincipalAppRoleAssignment -Id 9a19415d-5d2c-410b-b6c3-ccd0daa3f240

    id                   : XUEZmixdC0G2w8zQ2qPyQEb2xGZZr4xGjJfhcI-E4Aw
    creationTimestamp    : 2016-11-03T21:31:46.4671735Z
    appRoleId            : 5778995a-e1bf-45b8-affa-663a9f3f4d04
    principalDisplayName : Reporting API Application
    principalId          : 9a19415d-5d2c-410b-b6c3-ccd0daa3f240
    principalType        : ServicePrincipal
    resourceDisplayName  : Windows Azure Active Directory
    resourceId           : d80f4d2b-d115-44ad-b39e-69ebdbe6c9fe
    appRoleName          : Directory.Read.All

    .EXAMPLE
    Get-MSGServicePrincipalAppRoleAssignment -Id 9a19415d-5d2c-410b-b6c3-ccd0daa3f240 -ResolveIds
    CreationTimestamp            ResourceDisplayName    AppRoleName                  PrincipalDisplayName      PrincipalId
    -----------------            -------------------    -----------                  --------------------      -----------
    2016-11-03T21:31:46.4671735Z Windows Azure Active   Directory Directory.Read.All Reporting API Application 9a19415d-5d2c-410b-b6c3-ccd0daa3f240

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignments?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveIds
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
        #$res = Get-MSGObject -Type "servicePrincipals/$Id" -Filter "`$expand=appRoleAssignments"
        $res = Get-MSGObject -Type "servicePrincipals/$Id/appRoleAssignments"
        if ($res.StatusCode -ge 400)
        {
            return $res 
        }
        if ($ResolveIds)
        {
            foreach ($assignment in $res)
            {
                if (-not $appPermissionTable.ContainsKey($assignment.resourceId))
                {
                    $roles = (Get-MSGServicePrincipal -Id $assignment.resourceId -Properties appRoles)
                    BuildPermissionTable -AppId $assignment.resourceId -Roles $roles.appRoles
                }
                $permList = $appPermissionTable.Item($assignment.resourceId)
                Add-Member -InputObject $assignment -MemberType NoteProperty -Name appRoleName -Value $permList.Item($assignment.appRoleId)
                $assignment.PSOBject.TypeNames.Insert(0, 'MSGraph.servicePrincipals.resolvedAppRoleAssignments')
            }
        }
        $res
    }
}

function BuildPermissionTable
{
    param(
        [Parameter(Mandatory = $True)]
        [string]$AppId,

        [Parameter(Mandatory = $True)]
        [object]$Roles
    )

    $perm = @{}
    if (-not $appPermissionTable.ContainsKey($AppId))
    {
        $Roles | Select-Object Id, Value | ForEach-Object { $perm.Add($_.Id, $_.value) }
        try
        {
            $appPermissionTable.Add($AppId, $perm) 
        }
        catch
        {
            Write-Warning "AddPermissionTable: Failed to add perms to ${appId}"; return $null 
        }
    }
}
