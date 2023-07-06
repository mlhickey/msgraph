function Get-MSGObject
{
    <#
    .SYNOPSIS
    General worker routine, grab anything exposed via Graph.  This is also the underlying route OptionListfor Get-MSGUser, Get-MSGServicePrincipals and Get-MSGUserMembership

    .DESCRIPTION
    Worker routine to call into MS Graph for most any object type.  Different objects are exposed based on endpoint selected during Connect-MSG - if you don't see what
    you're looking for, try a different endpoint via Connect-MSG -graphVer {version}. Documentation can be found at https://developer.microsoft.com/en-us/graph/docs/overview/overview

    .PARAMETER Type
    Object type being queried. See https://developer.microsoft.com/en-us/graph/graph-explorer for the current list of toplevel types.  NOTE: These are case sensitive - if you get an error, double check case.

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER SearchString
    String to use as part of search.

    .PARAMETER authMode
    Authentication mode to use - user, app, delegated or ignore

    .PARAMETER Method
    Specifies the method to use - Get or Post

    .PARAMETER Body
    PSObject representation of required body parameters.  Get-MSGObject converts this to JSON before passing to Graph

    .EXAMPLE
    Reports:
    Get-MSGObject -Type reports/auditEvents -All  -Filter "(eventTime gt 2017-04-14T16:00:00Z and eventTime lt 2017-04-15T16:00:00Z)"

    .EXAMPLE
    Devices:
    Get-MSGObject -Type users/bscallan@microsoft.com/registeredDevices
    Get-MSGObject -Type devices/deviceId_096754c0-de03-46ca-8581-ec86dc1c884e

    .EXAMPLE
    Service Principals:
    Get-MSGObject -Type servicePrincipals -All

    .EXAMPLE
    With body and POST method:
        $body = @{ "securityEnabledOnly" = $false }
        Get-MSGObject -Type "users/bscalls@microsoft.com/getMemberGroups" -Body $body -Method POST

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [string]$SearchString,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'App', 'Delegated', 'Ignore')]
        [string]$authMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'POST', ignorecase = $true)]
        [string]$Method = 'GET',

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [string]$ObjectName = 'MSGraph',

        [Parameter(Mandatory = $false)]
        [string]$OptionList,

        [Parameter(Mandatory = $false)]
        [switch]$CountOnly
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ([string]::IsNullOrEmpty($authMode))
        {
            $authMode = $MSGAuthInfo.AuthType
        }
        if ($MSGAuthInfo.Initialized -ne $true -and $authMode -eq 'User')
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        $Url = [string]::Format('{0}/{1}/{2}', $MSGAuthInfo.GraphUrl, $MSGAuthInfo.GraphVersion, $Type.Trim())
        #region FilterProcessing

        if (-not [string]::IsNullOrEmpty($OptionList))
        {
            $queryFilter = $optionList
        }
        else
        {
            $queryFilter = ProcessCoreBoundParams -paramList $PSBoundParameters
        }

        if ($queryFilter -match 'top=(\d*)' -and [int]$Matches[1] -gt 999)
        {
            $count = [int]($Matches[1] / 999)
            $rem = $Matches[1] % 999
            $queryFilter = $queryFilter.Replace("top=$($Matches[1])", 'top=999')
        }
        #endregion FilterProcessing
        $fullHeader = @{ 'Content-Type' = 'application/json' }
        if ($Filter -match '\$count|\$orderBy|\$search')
        {
            $fullHeader.Add('ConsistencyLevel', 'eventual ')
        }

        if ($Method -match 'POST' -and $null -ne $Body)
        {
            $enc = New-Object 'System.Text.ASCIIEncoding'
            $jsonBody = ConvertTo-Json -InputObject $Body -Depth 10

            $byteArray = $enc.GetBytes($jsonBody)
            $contentLength = $byteArray.Length
            $fullHeader.Add('Content-Length', $contentLength)
        }
        else
        {
            $jsonBody = $Null
        }

        $objectType = $type.split('/')
        $objectType = $objectType[0, 2] -join '.'
        $objectType = "$ObjectName." + $objectType.Trim()

        if (-not [string]::IsNullOrEmpty($queryFilter))
        {
            $Url += "?$queryFilter"
        }
        $nextLink = $Url

        $Params = @{
            Uri      = $Url
            Method   = $Method
            Headers  = $fullHeader
            authMode = $authMode
            Body     = $jsonBody
        }
    }

    process
    {
        do
        {
            $Params['Uri'] = $nextLink
            $nextLink = $null

            $result = Invoke-SafeWebRequest @Params

            if ($result.StatusCode -ge 400)
            {
                switch ($ErrorActionPreference)
                {
                    'Continue'
                    {
                        $ex = New-Error -ErrorObject $result -AdditionalInfo $Type.Trim()
                        Write-Error -ErrorRecord $ex
                        return
                    }
                    'SilentlyContinue'
                    {
                        return $result.StatusCode
                    }
                }
            }

            if ($null -eq $result)
            {
                return $result
            }
            if ($CountOnly)
            {
                return $result.'@odata.count'
            }

            #region nextLinkProcessing
            $nextLink = ((Get-Member -InputObject $result).Where( { $_.Name -match 'nextLink' })).Name
            if ($null -ne $nextLink)
            {
                if ($All -or -- $count -gt 0)
                {
                    $nextLink = $result.$nextLink
                }
                elseif ($count -eq 0 -and $rem -gt 0)
                {
                    $nextLink = $result.$nextLink.Replace('top=999', "top=$rem")
                    $rem = 0
                }
                else
                {
                    $nextLink = $null
                }
            }
            #endregion nextLinkProcessing
            if ($result.PSOBject.Properties.Name -contains 'value')
            {
                $Objects = $result.value
            }
            else
            {
                $Objects = $result
            }
            # If property sets are specifed then the TypeNames work which enables default
            # output formatting via MSGraph.format.ps1xml doesn't need to happen
            $Objects | ForEach-Object { $_.PSOBject.Properties.Remove('@odata.context') }
            $Objects | ForEach-Object { $_.PSOBject.Properties.Remove('@odata.id') }
            #if (-not ($filter -match 'select=' -or $filter -match 'expand='))
            $addType = -not ($filter -match 'select=' -or $filter -match 'expand=')
            $Objects | ForEach-Object {
                $type = $_.'@odata.type'
                $_.PSObject.Properties.Remove('@odata.type')
                if ($addType)
                {
                    if ([string]::IsNullOrEmpty($type))
                    {
                        $_.PSOBject.TypeNames.Insert(0, $objectType.Trim())
                    }
                    else
                    {
                        $_.PSOBject.TypeNames.Insert(0, $type.Trim())
                    }
                }
            }
            $Objects
        } while ($null -ne $nextLink)
    }
}

function Get-MSGObjectById
{
    <#
    Documentation can be found at https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/directoryobject_getbyids
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            HelpMessage = 'A collection of resource types that specifies the set of resource collections to search')]
        [ValidateSet('user', 'group', 'device', 'directoryObject')]
        [string[]]$Type,

        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'A collection of ids for which to return objects. You can specify up to 1000 ids.')]
        [string[]]$Ids,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'App', 'Ignore')]
        [string]$authMode,

        [Parameter(Mandatory = $false)]
        [string]$Filter
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ([string]::IsNullOrEmpty($authMode))
        {
            $authMode = $MSGAuthInfo.AuthType
        }
        if ($MSGAuthInfo.Initialized -ne $true -and $authMode -eq 'User')
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    process
    {
        $body = @{ 'ids' = $ids }

        if (-not [string]::IsNullOrEmpty($Type))
        {
            $body.Add('types', $Type)
        }

        $result = Get-MSGObject -Type 'directoryObjects/getByIds' -Method POST -Body $body -Filter $Filter

        if ($result.StatusCode -ge 400)
        {
            switch ($ErrorActionPreference)
            {
                'Continue'
                {
                    $ex = New-Error -ErrorObject $result -AdditionalInfo $Type.Trim()
                    Write-Error -ErrorRecord $ex
                    return
                }
                'SilentlyContinue'
                {
                    return $null
                }
            }
        }
        $result
    }
}

function New-MSGObject
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [Alias('Body')]
        [object]$Object,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'App', 'Ignore')]
        [string]$authMode,

        [Parameter(Mandatory = $false)]
        [string]$ObjectName = 'MSGraph'

    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ([string]::IsNullOrEmpty($authMode))
        {
            $authMode = $MSGAuthInfo.AuthType
        }
        if ($MSGAuthInfo.Initialized -ne $true -and $authMode -eq 'User')
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $uri = [string]::Format('{0}/{1}/{2}', $MSGAuthInfo.GraphUrl, $MSGAuthInfo.GraphVersion, $Type.Trim())

        $objectType = $type.split('/')
        $objectType = $objectType[0, 2] -join '.'
        $objectType = "$ObjectName." + $objectType.Trim()
    }

    process
    {
        $enc = New-Object 'System.Text.ASCIIEncoding'
        $jsonBody = ConvertTo-Json -InputObject $Object -Depth 10

        $byteArray = $enc.GetBytes($jsonBody)
        $contentLength = $byteArray.Length
        $fullHeader = @{ 'Content-Type' = 'application/json'; 'Content-Length' = $contentLength }

        $result = Invoke-SafeWebRequest -Method POST -Uri $uri -Headers $fullHeader -Body $jsonBody -AuthMode $authMode

        if ($result.StatusCode -ge 400)
        {
            switch ($ErrorActionPreference)
            {
                'Continue'
                {
                    $ex = New-Error -ErrorObject $result -AdditionalInfo $Type.Trim()
                    Write-Error -ErrorRecord $ex
                    return
                }
                'SilentlyContinue'
                {
                    return $null
                }
            }
        }

        if ($null -ne $result)
        {
            $result.PSOBject.Properties.Remove('@odata.context');
            $type = $result.'@odata.type'
            if ([string]::IsNullOrEmpty($type))
            {
                $result.PSOBject.TypeNames.Insert(0, $objectType.Trim())
            }
            else
            {
                $result.PSOBject.TypeNames.Insert(0, $type.Trim())
            }
        }
        $result
    }
}
function Set-MSGObject
{
    <#
    .SYNOPSIS
    Update objects

    .DESCRIPTION

    Set-MSGObject allows you to perform updates on various objects via the MS Graph model.

    .PARAMETER Type
    Object type being queried. See https://developer.microsoft.com/en-us/graph/docs/concepts/v1-overview or https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/beta-overview
    for the available object types.  These equate to what you would append to the default URL in https://developer.microsoft.com/en-us/graph/graph-explorer

    .PARAMETER Id
    Argument that goes along with Type parameter, e.g. objectId of device, userPrincipalName of user

    .PARAMETER Method
    Method to use for updates.  Depending on the object class this can be either PATCH or POST

    .PARAMETER Body
    PSObject representation of required body parameters.  Set-MSGObject converts this to JSON before passing to Graph

    .EXAMPLE
    Set-MSGObject -Type devices -Id $ObjectId -Method PATCH -Body @{ accountEnabled = $false}

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [Alias('Body')]
        [object]$Object,

        [Parameter(Mandatory = $false)]
        [ValidateSet('PATCH', 'POST', 'DELETE', ignorecase = $true)]
        [string]$Method = 'PATCH',

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'App', 'KeyVault', 'Ignore')]
        [string]$authMode,

        [Parameter(Mandatory = $false)]
        [string]$ObjectName = 'MSGraph'
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ([string]::IsNullOrEmpty($authMode))
        {
            $authMode = $MSGAuthInfo.AuthType
        }
        if ($MSGAuthInfo.Initialized -ne $true -and $authMode -eq 'User')
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        $fullHeader = @{ 'Content-Type' = 'application/json' }
        $uri = [string]::Format('{0}/{1}/{2}', $MSGAuthInfo.GraphUrl, $MSGAuthInfo.GraphVersion, $Type.Trim())

        $objectType = "$ObjectName.HtmlWebResponseObject"
    }

    process
    {
        if ($id.Length -gt 0)
        {
            $uri += "/$($id.Trim())"
        }

        if ($null -ne $Object)
        {
            $enc = New-Object 'System.Text.ASCIIEncoding'
            $jsonBody = ConvertTo-Json -InputObject $Object -Depth 10

            $byteArray = $enc.GetBytes($jsonBody)
            $contentLength = $byteArray.Length
            $fullHeader.Add('Content-Length', $contentLength)
        }
        else
        {
            $jsonBody = $Null
        }

        $result = Invoke-SafeWebRequest -Method $Method -Uri $uri -Headers $fullHeader -Body $jsonBody -AuthMode $authMode

        if ($result.StatusCode -ge 400)
        {
            switch ($ErrorActionPreference)
            {
                'Continue'
                {
                    $ex = New-Error -ErrorObject $result -AdditionalInfo $Type.Trim()
                    Write-Error -ErrorRecord $ex
                    return
                }
                'SilentlyContinue'
                {
                    return $null
                }
            }
        }

        if ($null -ne $result)
        {
            $result.PSOBject.Properties.Remove('@odata.context')
            $type = $result.'@odata.type'
            if ([string]::IsNullOrEmpty($type))
            {
                $result.PSOBject.TypeNames.Insert(0, $objectType.Trim())
            }
            else
            {
                $result.PSOBject.TypeNames.Insert(0, $type.Trim())
            }
        }
        $result
    }
}

function Remove-MSGObject
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'App', 'KeyVault', 'Ignore')]
        [string]$authMode,

        [Parameter(Mandatory = $false)]
        [string]$ObjectName = 'MSGraph'
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ([string]::IsNullOrEmpty($authMode))
        {
            $authMode = $MSGAuthInfo.AuthType
        }
        if ($MSGAuthInfo.Initialized -ne $true -and $authMode -eq 'User')
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
            return $null
        }
        $uri = [string]::Format('{0}/{1}/{2}/{3}', $MSGAuthInfo.GraphUrl, $MSGAuthInfo.GraphVersion, $Type.Trim(), $Id.Trim())
        $fullHeader = @{ 'Content-Type' = 'application/json' }

        $objectType = "$ObjectName.HtmlWebResponseObject"
    }

    process
    {
        $result = Invoke-SafeWebRequest -Method Delete -Uri $uri -Headers $fullHeader -AuthMode $authMode

        if ($result.StatusCode -ge 400)
        {
            switch ($ErrorActionPreference)
            {
                'Continue'
                {
                    $ex = New-Error -ErrorObject $result -AdditionalInfo $Type.Trim()
                    Write-Error -ErrorRecord $ex
                    return
                }
                'SilentlyContinue'
                {
                    return $null
                }
            }
        }

        if ($null -ne $result)
        {
            $result.PSOBject.Properties.Remove('@odata.context')
            $type = $result.'@odata.type'
            if ([string]::IsNullOrEmpty($type))
            {
                $result.PSOBject.TypeNames.Insert(0, $objectType.Trim())
            }
            else
            {
                $result.PSOBject.TypeNames.Insert(0, $type.Trim())
            }
        }
        $result
    }
}
function Get-MSGLinkedObject
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Relationship,

        [Parameter(Mandatory = $false)]
        [switch]$GetLinksOnly,

        [Parameter(Mandatory = $false)]
        [switch]$All
    )

    $MSGAuthInfo = Get-MSGConfig
    if ([string]::IsNullOrEmpty($authMode))
    {
        $authMode = $MSGAuthInfo.AuthType
    }
    if ($MSGAuthInfo.Initialized -ne $true -and $authMode -eq 'User')
    {
        throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
    }

    if ($GetLinksOnly)
    {
        $objType = [string]::Format("{0}{1}/`$links/{2}", $Type.Trim(), $Id.Trim(), $Relationship)
    }
    else
    {
        $objType = [string]::Format('{0}{1}/{2}', $Type.Trim(), $Id.Trim(), $Relationship)
    }
    Get-MSGObject -Type $objType -All:$All
}

function ProcessCoreBoundParams
{
    param(
        [object]$paramList
    )

    $tList = @()
    $fList = @()
    #region AllProcessing
    # in case someone calls this direct with -All
    if ($paramList['All'])
    {
        if ($paramList['Filter'] -match "\`$top=(\d*)")
        {
            if ($Matches[1] -ne 999)
            {
                $paramList['Filter'] = $paramList['Filter'].Replace('top=(\d*)', 'top=999')
            }
        }
        else
        {
            $tlist += "`$top=999"
        }
    }
    #endregion AllProcessing
    #region BuildFilterList
    if (-not [string]::IsNullOrEmpty($paramList['SearchString']))
    {
        $tList += [uri]::EscapeDataString($paramList['SearchString'])
        $paramList['Filter'] = $paramList['Filter'].Replace("`$filter=", '')
    }

    if (-not [string]::IsNullOrEmpty($paramList['Filter']))
    {
        $tList += $paramList['Filter'].split('&')
    }

    $queryString = @()
    for ($idx = 0; $idx -lt $tList.Count; $idx++)
    {
        if ($tList[$idx] -notmatch "`\$")
        {
            $queryString += [uri]::EscapeDataString($tList[$idx])
        }
        else
        {
            $flist += $tList[$idx]
        }
    }

    if ($queryString.Count -gt 0)
    {
        $flist += "`$filter=$($queryString -join ' and ')"
    }
    #endregion BuildFilterList
    return $flist -join '&'
}
