function Get-MSGUser
{
    <#
    .SYNOPSIS
    Get group information

    .DESCRIPTION
    The Get-MSGUser cmdlet gets information about specified user in Azure Active Directory (Azure AD).

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

    .PARAMETER Search
      String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .PARAMETER AdvancedQuery
    Sets header to support advanced query options (see https://docs.microsoft.com/en-us/graph/aad-advanced-queries#support-for-filter-on-properties-of-azure-ad-directory-objects)

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE
    Get-MSGUser -CountOnly -Filter "userType eq 'Guest'"
    782146

    .EXAMPLE
    Get-MSGUser -Id user@microsoft.com -Properties displayName,accountEnabled

    accountEnabled  displayName
    --------------  -----------
            True    Mike Johnson

    .EXAMPLE
    Get-MSGUser -SearchString "Mike" -Top 3 -Properties displayName,refreshTokensValidFromDateTime

    displayName refreshTokensValidFromDateTime
    ----------- ------------------------------
    Mike        2016-04-06T15:22:56Z
    Mike        2014-11-13T03:42:52Z
    Mike        2014-04-15T20:13:52Z

    .EXAMPLE
    Get-MSGUser -CountOnly -Filter "userType eq 'Guest'"
    770018

    .EXAMPLE
    Get-MSGUser -Filter "onPremisesExtensionAttributes/extensionAttribute2 in ('50','53')" -CountOnly
    189293

    .EXAMPLE
     Get-MSGUser -Filter "endsWith(mail,'@hotmail.com')" -AdvancedQuery -TOP 2

    Id                                   DisplayName UserPrincipalName                                     UserType
    --                                   ----------- -----------------                                     --------
    0010425a-70d2-4f21-8713-5b3fde7bc795 은식 임      ian3013_hotmail.com#EXT#@microsoft.onmicrosoft.com    Guest
    00154281-b5ea-4aef-950d-b0522c0245e5 irenel1201   irenel1201_hotmail.com#EXT#@microsoft.onmicrosoft.com Guest

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-get?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the user.')]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

        [Parameter(ParameterSetName = 'My')]
        [ValidateNotNullOrEmpty()]
        [switch]$MyUser,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            HelpMessage = 'Search criteria.')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Filter',
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'My')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'My')]
        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'Property to expand. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'My')]
        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [string]$ExpandProperty,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]$All,

        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]$AdvancedQuery,

        [Parameter(ParameterSetName = 'Count')]
        [switch]$CountOnly
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        # Remove SearchString from lsit because we build an ANR search string for users
        #$null = $PSBoundParameters.Remove("SearchString")
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $id = [uri]::EscapeDataString($id)
                Get-MSGObject -Type "users/$id" -Filter $queryFilter
                break
            }
            'my'
            {
                Get-MSGObject -Type 'me' -Filter $queryFilter
                break
            }
            'search'
            {
                if ($SearchString -match '\w:\w')
                {
                    $queryFilter += "`$search=`"$SearchString`""
                    Get-MSGObject -Type 'users' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                }
                else
                {
                    Get-MSGObject -Type 'users' -SearchString (BuildUserANRSearchString -searchString $SearchString) -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                }
                break
            }
            { $PSItem -match 'topall|filter' }
            {
                Get-MSGObject -Type 'users' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            'count'
            {
                Get-MSGObject -Type 'users' -Filter $queryFilter -CountOnly
            }
        }
    }
}
