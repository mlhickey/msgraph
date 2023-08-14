<#
    Documentation can be found at https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/resources/device
#>
function New-MSGServicePrincipalOwner
{
    <#
    .SYNOPSIS
    Add an owner to the specified serviceprincipal

    .DESCRIPTION
    The Add-MSGServicePrincipalOwner cmdlet adds an owner to the specified serviceprincipal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER RebObjectId
    Specifies the ID of the Active Directory object to add

    .EXAMPLE
    Get-MSGServicePrincipalOwners -Id bd4136eb-55f4-4db2-a368-aed60b492f41

    Id                                   DisplayName     UserPrincipalName     UserType
    --                                   -----------     -----------------     --------
    c5480b7b-4c04-474c-8f4b-76a9df87d602 Nick Starkebaum nistar@microsoft.com  Member
    f839606d-4143-4ed4-a049-56c26049a343 Mike Hickey     mhickey@microsoft.com Member

    .LINK
     https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-owners?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the serviceprincipal.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'RefObjectId of the user to add')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$RefObjectId
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
        $body = @{
            '@odata.id' = "https://graph.microsoft.com/$($MSGAuthInfo.GraphVersion)/directoryObjects/$RefObjectId"
        }

        if ($PSCmdlet.ShouldProcess("$Id", 'Create owner assignment'))
        {
            New-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id/owners/`$ref" -Body $body
        }
    }
}

