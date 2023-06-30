function Get-MSGApplicationExpiredStatus
{
    <#
    .SYNOPSIS
    Returns applications that are either expired or exceeed the maximum credential period

    .DESCRIPTION
    The Get-MSGApplicationExpiredStatus returns applications that are either expired or exceeed the maximum credential period

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .PARAMETER SearchString
    Specifies a search string.  Performs match based on startsWith(displayName, SearchString)

    .PARAMETER Top
    Specifies the maximum number of records to return.  Note that this determines the number of applications to be processed, not the final result set

    .PARAMETER All
    If true, return all applications. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGApplicationExpiredStatus -AppId 375a9d9e-9fc3-4bcd-b24b-77c29e26ff10

    Id                                   Name                      PassExpiration        PassThresholdExceededDays CertExpiration CertThresholdExceededDays
    --                                   ----                      --------------        ------------------------- -------------- -------------------------
    375a9d9e-9fc3-4bcd-b24b-77c29e26ff10 Reporting API Application 6/24/2017 10:45:27 AM None                      None           None

    #>

    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
            HelpMessage = 'AppId of the application')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'SearchString',
            HelpMessage = 'Partial/complete displayname.')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'SearchString')]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'SearchString')]
        [Parameter(ParameterSetName = 'TopAll')]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        $propSet = "`$select=id,appId,passwordCredentials,keyCredentials,displayName,createdDateTime"

        if (-not $All)
        {
            $propSet = "`$top=$top&$propset"
        }
    }

    process
    {
        $Error.Clear()
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {

            'appid'
            {
                $allAzureItems = Get-MSGObject -Type 'applications' -Filter "Appid eq '$AppId'&$propSet"
                break
            }
            'objectid'
            {
                $allAzureItems = Get-MSGObject -Type 'applications' -Filter "id eq '$Id'&$propset"
                break
            }
            'searchstring'
            {
                $allAzureItems = Get-MSGObject -Type 'applications' -SearchString "startswith(displayName,'$SearchString')" -Filter $propSet -All:$All
                break
            }
            'topall'
            {
                $allAzureItems = Get-MSGObject -Type 'applications' -Filter $propSet -All:$All
                break
            }
        }

        foreach ($item in $allAzureItems)
        {
            if ($null -eq $item.Id)
            {
                continue
            }

            $script:itemObjectProperties = [PSCustomObject][Ordered]@{
                PSTypeName                = 'MSGraph.ExpiredStatus'
                Name                      = 'None'
                Id                        = 'None'
                CreationDate              = 'None'
                OwnerList                 = 'None'
                PassExpiration            = 'None'
                PassThresholdExceededDays = 'None'
                CertExpiration            = 'None'
                CertThresholdExceededDays = 'None'
            }

            if ($item.PasswordCredentials.Count)
            {
                $results = ProcessCredentials -cObjects $item.PasswordCredentials
                if ($results.Expiration -ne 'None')
                {
                    $itemObjectProperties.PassExpiration = $results.Expiration
                    $itemObjectProperties.PassThresholdExceededDays = $results.Threshold
                }
            }

            if ($item.KeyCredentials.Count -ge 1)
            {
                $results = ProcessCredentials -cObjects $item.KeyCredentials
                if ($results.Expiration -ne 'None')
                {
                    $itemObjectProperties.CertExpiration = $results.Expiration
                    $itemObjectProperties.CertThresholdExceededDays = $results.Threshold
                }
            }

            $owners = GetOwnerList -Id $item.Id
            $itemObjectProperties.Name = $item.displayName
            $itemObjectProperties.Id = $item.appId
            $itemObjectProperties.CreationDate = $item.createdDateTime
            $itemObjectProperties.OwnerList = $owners.upnList
            $itemObjectProperties
        }
    }
}
