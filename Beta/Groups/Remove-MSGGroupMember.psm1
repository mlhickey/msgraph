function Remove-MSGGroupMember
{
    <#
    .SYNOPSIS
    Removes a group member from a group

    .DESCRIPTION
    The Remove-MSGGroupMember cmdlet removes a member from a group in Azure Active Directory

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER MemberId
    Specifies the ID of the member to remove

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-delete-members?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the group")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the user")]
        [string]$MemberId
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
            $queryString = "groups/{0}/members/{1}" -f $Id, $MemberId
            Remove-MSGObject -Type $queryString -Id "`$Ref"
        }
    }
}
