function Get-MSGServicePrincipalMembership
{
    <#
    .SYNOPSIS
    Get all objects serviceprincipal is member of

    .DESCRIPTION
    The Get-MSGServicePrincipalMembership cmdlet lists all objects the specified servicePrincipal is a member of

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a servicePrincipal in Azure AD.  This parameter is also aliased to ObjectId for named pipeline processing

    .PARAMETER OnlySGs
    Specifies whether only security enabled groups should be part of the result set.

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .LINK
    https://docs.microsoft.com/en-us/graph/api/directoryobject-getmembergroups?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the servicePrincipal.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Return only security groups')]
        [bool]$OnlySGs = $false,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'TopAll')]
        [int]$Top = 100,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'TopAll')]
        [switch]$All,

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
    }

    process
    {
        $body = @{ 'securityEnabledOnly' = $OnlySGs }
        $body
        $typeString = "servicePrincipals/$id/getMemberObjects"
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $typeString -Body $body -All:$All -Method POST
                break;
            }

            'count'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $typeString -Body $body -CountOnly -Method POST
                break
            }
        }
    }
}
