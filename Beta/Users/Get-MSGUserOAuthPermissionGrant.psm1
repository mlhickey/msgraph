function Get-MSGUserOAuthPermissionGrant
{
    <#
    .SYNOPSIS
    Get OAuth permission grants

    .DESCRIPTION
    The Get-MSGUserOAuthPermissionGrantscmdlet gets the list of oAuth2PermissionGrant entities, which represent delegated permissions granted to enable a client application to access an API on behalf of the user. for the specified user(s)

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER MyUser
    Returns information based on the current authenticated user

    .PARAMETER SearchString
    String to use as part of search.  This will perform a ANR-type query across the following properties:

        userPrincipalName
        mailNickName
        mail
        jobTitle
        displayName
        department
        country
        city

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-list-oauth2permissiongrants?view=graph-rest-1.0&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = "Id")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,

        [Parameter(ParameterSetName = "My")]
        [ValidateNotNullOrEmpty()]
        [switch]$MyUser,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search",
            HelpMessage = "Partial/complete displayname of the group.")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties = @("id"),

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $null = $PSBoundParameters.Remove("SearchString")
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        $ulist = @()
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "my"
            {
                $list = Get-MSGObject -Type "me/oauth2PermissionGrants"
                return UpdateTypes $list
            }
            "id"
            {
                $id = [uri]::EscapeDataString($id)
                $list = Get-MSGObject -Type "users/$id/oauth2PermissionGrants" -All
                return UpdateTypes $list
            }
            "search"
            {
                if ($SearchString -match "\w:\w")
                {
                    $queryFilter += "`$search=`"$SearchString`""
                    $uList = Get-MSGObject -Type "users"  -Filter $queryFilter -All:$All
                }
                else
                {
                    $uList = Get-MSGObject -Type "users" -SearchString (BuildUserANRSearchString -SearchString $SearchString) -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                }
                break
            }
            default
            {
                Write-Warning "You must specify either an ObjectId or a searchable string"
                return $null
            }
        }
        if ($ulist.StatusCode -ge 400) { return $ulist }
        foreach ($u in $ulist)
        {
            $list = Get-MSGObject -Type "users/$($u.id)/oauth2PermissionGrants" -All
            UpdateTypes $list
        }
    }
}

function UpdateTypes
{
    param (
        [object]$objectList
    )

    $objectList | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, "MSGraph.oAuth2Permissiongrants") }
    $objectList
}