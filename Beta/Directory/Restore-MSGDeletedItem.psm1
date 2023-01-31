function Restore-MSGDeletedItem
{
    <#
    .SYNOPSIS
    Restore deleted items from Azure Active Directory

    .DESCRIPTION
    The Restore-MSGDeletedItem cmdlet returns a list of deleted items.  This cmdlet currently supports retrieving object types of groups (microsoft.graph.group) or users (microsoft.graph.user) from deleted items

    .PARAMETER Id
    SPecifies the id (ObjectId) of a deleted object

    .EXAMPLE

    .LINK
     https://docs.microsoft.com/en-us/graph/api/directory-deleteditems-list?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            HelpMessage = "Type of deleted directory object to return, user or group")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id
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
        if ($PSCmdlet.ShouldProcess("$Id", "Restore deleted item"))
        {
            $Type = "directory/deletedItems/$Id/restore"
            Set-MSGObject -Type $Type -Method POST
        }
    }
}
