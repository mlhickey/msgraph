function Add-MSGGroupMember
{
    <#

    .SYNOPSIS
    Add member to specified group

    .DESCRIPTION
    The Add-MSGGroupMember cmdlet adds a member to an Azure Active Directory group

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER RefObjectId
    Specifies the ID of the Azure Active Directory object that will be assigned as member

    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-post-members?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the group")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the user to add")]
        [Alias("RefObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$ReFId
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
        $typeString = "groups/{0}/members" -f $Id
        $bodyString = "{0}/{1}/directoryObjects/{2}" -f $MSGAuthInfo.GraphUrl, $MSGAuthInfo.GraphVersion, $ReFId
        $body = @{ "@odata.id" = $bodyString }
        Set-MSGObject -Type $typeString -Id "`$ref" -Body $body -Method POST
    }
}
