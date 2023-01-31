function Remove-MSGServicePrincipalOwner
{
    <#
    .SYNOPSIS
    Removes an owner from the specified serviceprincipal

    .DESCRIPTION
    The Remove-MSGServicePrincipalOwner cmdlet removes an owner from the specified serviceprincipal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER RebObjectId
    Specifies the ID of the Active Directory object to remove

    .EXAMPLE

    .LINK
     https://docs.microsoft.com/en-us/graph/api/serviceprincipal-delete-owners?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the serviceprincipal.")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the user to remove")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$RefObjectId
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
        $body = @{
            '@odata.id' = "https://graph.microsoft.com/$($MSGAuthInfo.GraphVersion)/directoryObjects/$RefObjectId"
        }

        if ($PSCmdlet.ShouldProcess("$Id", "Remove owner assignment"))
        {
            Set-MSGObject -Type "servicePrincipals/$id/owners" -Id "`$ref" -Body $body -Method DELETE
        }
    }
}

