function Remove-MSGGroupOwner
{
    <#
    .SYNOPSIS
    Removes an owner from a group

    .DESCRIPTION
    The Remove-MSGGroupOwner cmdlet removes a removes an owner from a group in Azure Active Directory

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER OwnerId
    Specifies the ID of the member to remove

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-delete-members?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the group")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the owner")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$OwnerId
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
        if ($PSCmdlet.ShouldProcess("$Id", "Delete"))
        {
            $queryString = "groups/{0}/owners/{1}" -f $Id, $OwnerId
            Remove-MSGObject -Type $queryString -Id "`$Ref"
        }
    }
}

