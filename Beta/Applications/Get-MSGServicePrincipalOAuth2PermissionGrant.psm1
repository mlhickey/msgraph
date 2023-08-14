function Get-MSGServicePrincipalOAuth2PermissionGrant
{
    <#
    .SYNOPSIS
    Gets the oAuth2PermissionGrant associaged with the specifed service principal

    .DESCRIPTION
    The Get-MSGServicePrincipalOAuth2PermissionGrant cmdlet returns the oAuth2PermissionGrant associaged with the specifed service principal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER Top
    Specifies the number of items to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER OnlyAdminConsented
    Swith to restrict results to admin consented grants

    .PARAMETER ResolveIds
    Resolve Graph API results

    .PARAMETER All
    Returns all associated grants

    .EXAMPLE
    Get-MSGServicePrincipalOAuth2PermissionGrant -Id dbe11260-3664-40c4-ae39-60ae65bca24f -Top 2

    ClientName    PrincipalName   PrincipalId                          Scope             Scope             Scope
    ----------    -------------   -----------                          -----             -----             -----
    discoapilayer Amarendra Singh 862d2e8a-5e9f-439c-97dc-4d93eaa618d6 UserProfile.Read  UserProfile.Read  UserProfile.Read
    discoapilayer Shamsha Khan    941ea60d-05fc-4cf1-b00e-d800076efe7a UserProfile.Read  UserProfile.Read  UserProfile.Read

    .EXAMPLE
    Get-MSGServicePrincipalOAuth2PermissionGrant -Id 3773d910-6134-4574-af1a-4034c6200768 -Raw

    Id                                          ResourceId                           ConsentType   Scope
    --                                          ----------                           -----------   -----
    ENlzNzRhdEWvGkA0xiAHaI5JnbGHZlZBhpouipWp1lk b19d498e-6687-4156-869a-2e8a95a9d659 AllPrincipals SecurityActions.Read.All IdentityRiskyUser.Read.All ...

    .LINK
    https://docs.microsoft.com/en-us/graph/api/oauth2permissiongrant-get?view=graph-rest-beta
    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Id',
            HelpMessage = 'Id of the servicePrincipal.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Id')]
        [int]$Top = 100,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'TopAll',
            HelpMessage = 'Return all grants')]
        [Parameter(ParameterSetName = 'Id')]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [switch]$OnlyAdminConsented,

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
        $argList = @()

        if (-not [string]::IsNullOrEmpty($Id))
        {
            $argList += "clientId eq '$id'"
        }

        if ($OnlyAdminConsented)
        {
            $argList += "consentType eq 'AllPrincipals'"
        }

        $filterArg = $argList -join ' and '

        if (-not [string]::IsNullOrEmpty($properties))
        {
            $filterArg += "`$select="
            $propFilter += $properties -join ','
        }

        if (-not $All)
        {
            $filterArg += "&`$top=$top"
        }

        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'oAuth2Permissiongrants ' -Filter $filterArg -All:$All

        if ($res.StatusCode -ge 400)
        {
            return $res 
        }

        if ($ResolveIds.IsPresent)
        {
            foreach ($r in $res)
            {
                $resolvedObject = [PSCustomObject][Ordered]@{
                    PSTypeName   = 'MSGraph.ExpandedoAuth2PermissionGrant'
                    ClientId     = $r.clientId
                    ClientName   = (Get-MSGObjectById -Ids $r.clientId -Filter "`$select=displayName").displayName
                    ConsentType  = $r.consentType
                    ExpiryTime   = $r.expiryTime
                    Id           = $r.Id
                    ResourceId   = $r.resourceId
                    ResourceName = (Get-MSGObjectById -Ids $r.resourceId -Filter "`$select=displayName").displayName
                    Scope        = $r.scope
                    StartTime    = $r.startTime
                }
                if (-not $OnlyAdminConsented -and $null -ne $r.principalId)
                {
                    Add-Member -InputObject $resolvedObject -MemberType NoteProperty -Name PrincipalId -Value $r.principalId
                    Add-Member -InputObject $resolvedObject -MemberType NoteProperty -Name PrincipalName -Value (Get-MSGObjectById $r.principalId -Filter "`$select=displayName").displayName
                }
                $resolvedObject
            }
        }
        else
        {
            $res
        }
    }
}
