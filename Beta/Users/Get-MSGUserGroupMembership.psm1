function Get-MSGUserGroupMembership
{
    <#
    .SYNOPSIS
    Get groups that user is member of

    .DESCRIPTION
    The Get-MSGUserGroupMembership cmdlet returns a list of groups that the specified user is a member of.  The returned list is a collection of objectIds

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId and UserPrincipalName for named pipeline processing

    .PARAMETER MyUser
    Returns information based on the current authenticated user

    .PARAMETER OnlySGs
    Restrict returned groups to only security groups


    .PARAMETER QueryType
    Return membership based on the following query type.  Default is Direct
        - Direct
        - Transitive

    .EXAMPLE
    (Get-MSGUserGroupMembership -Id user@microsoft.com).Count
    547

    .EXAMPLE
    (Get-MSGUserGroupMembership -Id user@microsoft.com -OnlySGs).Count
    393

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-getmembergroups?view=graph-rest-beta&tabs=http
    https://docs.microsoft.com/en-us/graph/api/user-list-memberof?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding(DefaultParameterSetName = 'My')]
    [Alias('Get-MSGUserMembership')]
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
        [switch]$MyUser,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Get either direct or transitive membership of specifed group')]
        [ValidateSet('Direct', 'Transitive')]
        [string]$QueryType = 'Direct',

        [Parameter(Mandatory = $false,
            HelpMessage = 'Return only security groups')]
        [switch]$OnlySGs,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Filter',
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'My')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [string]$Filter,

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
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        if ($queryType -match 'Direct')
        {
            $cmd = 'memberOf'
            $method = 'GET'

        }
        else
        {
            $cmd = 'getMemberGroups'
            $method = 'POST'
            $body = @{ 'securityEnabledOnly' = $OnlySGs.IsPresent }
        }

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $id = [uri]::EscapeDataString($id)
                $typeString = 'users/{0}' -f $Id
                break
            }
            'my'
            {
                $typeString = 'me'
                break
            }
        }
        $queryString = '{0}/{1}' -f $typeString, $cmd

        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $queryString -Method $method -Body $body -Filter $queryFilter
    }
}
