function Get-MSGUserLastSigninActivity
{
    <#
    .SYNOPSIS
    Get last signin information for specified user

    .DESCRIPTION
    The Get-MSGUserLastSigninActivity cmdlet gets the last signin time for the specified user

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/user_list_owneddevices

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the User.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
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
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        if (-not [string]::IsNullOrEmpty($Id))
        {
            # test for GUID
            try
            {
                $null = [System.Guid]::Parse($Id)
            }
            catch
            {
                $id = [uri]::EscapeDataString($id)
                $Id = (Get-MSGObject -Type ("users/{0}" -f $Id) -Filter "`$select=id").Id
            }
            Get-MSGObject -Type users -Filter "id eq '$Id'&`$select=id,displayName,signinActivity"
        }
        else
        {
            $queryFilter += "&`$select=id,displayName,signinActivity"
            Get-MSGObject -Type users -Filter $queryFilter -All:$All
        }
    }
}
