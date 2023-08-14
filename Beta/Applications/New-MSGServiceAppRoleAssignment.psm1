function New-MSGServiceAppRoleAssignment
{
    <#
    .SYNOPSIS
    Assigns a service principal to an application role

    .DESCRIPTION
    The New-MSGServiceAppRoleAssignment cmdlet assigns a service principal to an application role in Azure Active Directory (AD)

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER ResourceId
    Specifies the application id of the  resource being accessed

    .PARAMETER RoleName
    Specifies the name of the desired role, e.g. Group.Read.All

    .PARAMETER RoleId
    Specifies the id of the desired role, e.g. 5b567255-7703-4780-807c-7be8301ae99b

    .EXAMPLE
    New-MSGServiceAppRoleAssignment -Id "49223a9d-ba1b-4260-90a2-4571e42823d7" -ResourceId "00000003-0000-0000-c000-000000000000" -RoleName "Group.Read.All"

        id                   : nToiSRu6YEKQokVx5Cgj16vkmpTJ_4RMvXj7ziLjoXI
        creationTimestamp    : 2020-09-10T19:10:51.6055258Z
        appRoleId            : 5b567255-7703-4780-807c-7be8301ae99b
        principalDisplayName : DSRE CA Reader
        principalId          : 49223a9d-ba1b-4260-90a2-4571e42823d7
        principalType        : ServicePrincipal
        resourceDisplayName  : Microsoft Graph
        resourceId           : 15ab8882-e330-4e7f-9157-1624e87cb3b5

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignments?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal.')]
        [Alias('ObjectId', 'PrincipalId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Application id of the resource.')]
        [guid]$ResourceId,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Resource application roleName to assign')]
        [string]$RoleName,

        [Parameter(Mandatory = $false,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Resource application roleId to assign')]
        [string]$RoleId
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
        $ResourceSP = Get-MSGServicePrincipal -Filter "appId eq '$ResourceId'"
        if ($null -eq $ResourceSP)
        {
            throw "Unable to resolve $ResourceId "
        }

        if ([string]::IsNullOrEmpty($RoleName) -and [string]::IsNullOrEmpty($RoleId))
        {
            throw 'You must specify either an roleName or roleId'
        }
        elseif (-not [string]::IsNullOrEmpty($RoleName))
        {
            $RoleId = $ResourceSP.appRoles.Where( { $_.value -eq $RoleName }).Id
            if ($null -eq $RoleId)
            {
                throw "Unable to find role $RoleName in resource $($ResourceSP.DisplayName)/$($ResourceId)"
            }
        }

        $roleAssignment = [PSCustomObject][Ordered]@{
            principalId = $Id
            resourceId  = $ResourceSP.Id
            appRoleId   = $RoleId
        }

        if ($PSCmdlet.ShouldProcess("$Id", 'Create approle assignment'))
        {
            New-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id/appRoleAssignments" -Body $roleAssignment
        }
    }
}
