function Get-MSGOAuth2PermissionGrant
{
    <#
    .SYNOPSIS
    Gets the oAuth2PermissionGrant associaged with the specifed service principal

    .DESCRIPTION
    The Get-MSGOAuth2PermissionGrant cmdlet returns the oAuth2PermissionGrant associaged with the specifed service principal

    .PARAMETER Id
    Specifies the Id of the grant.

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
     Get-MSGOAuth2PermissionGrant  -Top 1

    ClientName    PrincipalName   PrincipalId                          Scope             Scope             Scope
    ----------    -------------   -----------                          -----             -----             -----
    discoapilayer Amarendra Singh 862d2e8a-5e9f-439c-97dc-4d93eaa618d6 UserProfile.Read  UserProfile.Read  UserProfile.Read

    .EXAMPLE
    Get-MSGOAuth2PermissionGrant -Id YBLh22Q2xECuOWCuZbyiTytND9gV0a1Es55p69vmyf6KLi2Gn16cQ5fcTZPqphjW

    ClientName    PrincipalName   PrincipalId                          Scope             Scope             Scope
    ----------    -------------   -----------                          -----             -----             -----
    discoapilayer Amarendra Singh 862d2e8a-5e9f-439c-97dc-4d93eaa618d6 UserProfile.Read  UserProfile.Read  UserProfile.Read

    .EXAMPLE
    Get-MSGOAuth2PermissionGrant -Id YBLh22Q2xECuOWCuZbyiTytND9gV0a1Es55p69vmyf6KLi2Gn16cQ5fcTZPqphjW -Raw

    Id                                                               ResourceId                           ConsentType Scope
    --                                                               ----------                           ----------- -----
    YBLh22Q2xECuOWCuZbyiTytND9gV0a1Es55p69vmyf6KLi2Gn16cQ5fcTZPqphjW d80f4d2b-d115-44ad-b39e-69ebdbe6c9fe Principal   UserProfile.Read

    .LINK
    https://docs.microsoft.com/en-us/graph/api/oauth2permissiongrant-get?view=graph-rest-beta
    #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "Id of the OAuth grant")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "TopAll")]
        [int]$Top = 100,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(Mandatory = $false,
            ParameterSetName = "TopAll",
            HelpMessage = "Return all grants")]
        [switch]$All,

        [Parameter(Mandatory = $false,
            ParameterSetName = "TopAll")]
        [switch]$OnlyAdminConsented,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveIds
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
        $argList = @()
        $typeString = "oAuth2Permissiongrants"

        if (-not [string]::IsNullOrEmpty($Id))
        {
            $typeString = "oAuth2Permissiongrants/$id"
        }

        if ($OnlyAdminConsented)
        {
            $argList += "consentType eq 'AllPrincipals'"
        }

        $filterArg = $argList -join " and "

        if (-not [string]::IsNullOrEmpty($properties))
        {
            $filterArg += "`$select="
            $propFilter += $properties -join ","
        }

        if (-not $All)
        {
            $filterArg += "&`$top=$top"
        }

        $res = Get-MSGObject -Type $typeString -Filter $filterArg -All:$All
        if ($res.StatusCode -ge 400) { return $res }
        if ($ResolveIds.IsPresent)
        {
            foreach ($r in $res)
            {
                $resolvedObject = [PSCustomObject][Ordered]@{
                    PSTypeName   = "MSGraph.ExpandedoAuth2PermissionGrant"
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
