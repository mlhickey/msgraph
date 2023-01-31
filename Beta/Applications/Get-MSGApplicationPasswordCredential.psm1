function Get-MSGApplicationPasswordCredential
{
    <#
    .SYNOPSIS
    Get credentials assocatied with the specifed id

    .DESCRIPTION
    The Get-MSGApplicationPasswordCredential cmdlet gets information about credential objects associated with the specified id

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .EXAMPLE
     Get-MSGApplicationPasswordCredential -Id 7f3ea722-a5a6-4252-aada-c204888aacf4


    customKeyIdentifier :
    endDateTime         : 2022-09-14T00:42:39.908Z
    keyId               : eb5d0b79-fe4e-42d3-ae8f-d2bdb12c06e6
    startDateTime       : 2020-09-14T01:01:04.412Z
    secretText          :
    hint                : A~6
    displayName         : Password uploaded on Sun Sep 13 2020
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the application")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "AppId",
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "AppId of the application")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$AppId
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
                $res = Get-MSGObject -Type "applications/$Id" -Filter "`$select=passwordCredentials"
                break
            }
            "appid"
            {
                $res = Get-MSGObject -Type "applications" -Filter "appId eq '$AppId'&`$select=passwordCredentials"
                break
            }
        }
        if ($res.StatusCode -ge 400) { return $res }
        $res | Select-Object -ExpandProperty passwordCredentials
    }
}
