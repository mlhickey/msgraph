function Get-MSGUserAppRoleAssignment
{
    <#
    .SYNOPSIS
    Get application assignments

    .DESCRIPTION
    The Get-MSGUserAppRoleAssignment cmdlet gets the application assignment information for the specified user(s)

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

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
    https://docs.microsoft.com/en-us/graph/api/user-list-approleassignments?view=graph-rest-beta&tabs=http
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

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search",
            HelpMessage = "Partial/complete displayname of the group.")]
        [Parameter(ParameterSetName = "Filter")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [Parameter(ParameterSetName = "Filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties = @("id"),

        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(Mandatory = $false)]
        [switch]$All
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
            "id"
            {
                $id = [uri]::EscapeDataString($id)
                $ulist = Get-MSGObject -Type "users/$id" -Filter $queryFilter
                break
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
                    $uList = Get-MSGObject -Type "users" -SearchString (BuildUserANRSearchString -SearchString $SearchString) -Filter $queryFilter -All:$All
                }
                break
            }
            default
            {
                Write-Warning "You must specify either an ObjectId or a searchable string"
                return $null
            }
        }

        foreach ($u in $ulist)
        {
            Get-MSGObject -Type "users/$($u.id)/appRoleAssignments" -All:$All
        }
    }
}
