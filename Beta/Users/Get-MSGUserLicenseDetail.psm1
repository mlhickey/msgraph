function Get-MSGUserLicenseDetail
{
    <#
    .SYNOPSIS
    Get all objects user is member of

    .DESCRIPTION
    The Get-MSGUserLicenseDetail cmdlet lists all objects the specified user is a member

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to Id and UserPrincipalName for named pipeline processing

    .PARAMETER MyUser
    Returns information based on the current authenticated user

    .PARAMETER OnlySGs
    Specifies whether only security enabled groups should be part of the result set.

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-getmemberobjects?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = "My")]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the User.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,


        [Parameter(ParameterSetName = "My")]
        [switch]$MyUser
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                $id = [uri]::EscapeDataString($id)
                $typeString = "users/{0}/licenseDetails" -f $Id
                break
            }
            "my"
            {
                $typeString = "me/licenseDetails"
                break
            }
        }

        $res = Get-MSGObject -Type $typeString

        if ($null -ne $res -and $res.StatusCode -lt 300)
        {
            $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, "MSGraph.licenseDetails") }
        }
        $res
    }
}
