function Get-MSGUserDirectReport
{
    <#
    .SYNOPSIS
     Get users' direct reports

    .DESCRIPTION
    The Get-MSGUserDirectReport cmdlet lists all objects the specified user is a member

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to Id and UserPrincipalName for named pipeline processing

    .PARAMETER MyUser
    Returns information based on the current authenticated user

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-list-directreports?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Either the ObjectId or the UserPrincipalName of the User.')]
        [Alias('ObjectId', 'UserPrincipalName')]
        [string]$Id,

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

        [Parameter(ParameterSetName = 'My')]
        [switch]$MyUser
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $id = [uri]::EscapeDataString($id)
                $typeString = 'users/{0}/directReports' -f $Id
                break
            }
            'my'
            {
                $typeString = 'me/directReports'
                break
            }
        }

        Get-MSGObject -Type $typeString
    }
}
