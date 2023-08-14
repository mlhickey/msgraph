function Add-MSGGroupOwner
{
    <#
    .SYNOPSIS
    Add owner to specified group

    .DESCRIPTION
    The Add-MSGGroupOwner cmdlet adds an owner to an Azure Active Directory group

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER RefObjectId
    Specifies the ID of the Azure Active Directory object that will be assigned as owner

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-post-owners?view=graph-rest-beta&tabs=http

    #>

    [CmdletBinding()]
    [Alias('Add-MSGgraphGroupOwner')]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the group')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the user to add')]
        [Alias('RefObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$ReFId,

        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Type of owner to add: User or ServicePrincipal')]
        [ValidateSet(
            'User',
            'ServicePrincipal')]
        [string]$OwnerType = 'User'
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
        $ownerType = camelCase $OwnerType
        $typeString = 'groups/{0}/owners' -f $Id
        $bodyString = '{0}/{1}/{2}s/{3}' -f $MSGAuthInfo.GraphUrl, $MSGAuthInfo.GraphVersion, $ownerType, $ReFId
        $body = @{ '@odata.id' = $bodyString }
        Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $typeString -Id "`$ref" -Body $body -Method POST
    }
}
