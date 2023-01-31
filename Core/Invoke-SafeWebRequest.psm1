function  SetAuthHeader
{
    param(
        [string]$AuthMode
    )

    $AuthParams = @{
        'Tenant'        = $MSGAuthInfo.TenantId
        'ClientId'      = $MSGAuthInfo.ClientId
        'GraphEndPoint' = $MSGAuthInfo.GraphUrl
        'Authority'     = $MSGAuthInfo.Authority
    }
    switch ($AuthMode.ToLower())
    {
        'user'
        {
            $authHeader = Get-UserAuthenticationResult @AuthParams
            break
        }
        'app'
        {
            $AuthParams.Add('StoreLocation', $MSGAuthInfo.StoreLocation)
            if (-not [string]::IsNullOrEmpty($MSGAuthInfo.ThumbPrint))
            {
                $AuthParams.Add('Thumbprint', $MSGAuthInfo.ThumbPrint)
            }
            elseif (-not [string]::IsNullOrEmpty($MSGAuthInfo.Certificate))
            {
                $AuthParams.Add('CertificateName', $MSGAuthInfo.Certificate)
            }
            else
            {
                throw 'Missing thumbprint or name for certificate to use'
            }
            $authHeader = Get-AppAuthenticationResult @AuthParams
            break
        }
        'delegated'
        {
            $authHeader = "Bearer $(Get-DelegatedAuthentication)"
            break
        }
    }
    return $authHeader
}
function Invoke-SafeWebRequest
{
    <#

        .EXAMPLE

        Invoke-SafeWebRequest -Uri "https://management.azure.com/subscriptions?api-version=2014-04-01" -Headers $header -Method GET -Verbose -AuthMode Ignore

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectUsageOfAssignmentOperator', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PATCH', 'DELETE', ignorecase = $true)]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $false)]
        [object]$Headers,

        [Parameter(Mandatory = $false)]
        [object]$Body,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]$UseBasicParsing,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'App', 'Delegated', 'Ignore')]
        [string]$AuthMode
    )

    begin
    {
        $_result = $null
        $retryCount = 0
        $MSGAuthInfo = Get-MSGConfig
        if ([string]::IsNullOrEmpty($AuthMode))
        {
            $AuthMode = $MSGAuthInfo.AuthType
        }


        $authHeader = SetAuthHeader -AuthMode $AuthMode

        if ($null -eq $authHeader -and $authMode -ne 'Ignore')
        {
            Write-Error 'Invoke-SafeWebRequest::Unable to create new authentication header'
            return $null
        }
        elseif ($null -ne $Headers)
        {
            if ($Headers.Contains('Authorization'))
            {
                [void]$Headers.Remove('Authorization')
            }
            $Headers.Add('Authorization', $authHeader)
        }
        else
        {
            $Headers = @{ 'Authorization' = "$authHeader" }
        }

        $Params = @{
            Uri     = $Uri
            Method  = $Method
            Headers = $Headers
            Verbose = $VerbosePreference
            Debug   = $DebugPreference
        }

        if ($UseBasicParsing)
        {
            $Params.Add('UseBasicParsing', $UseBasicParsing)
        }
        if ($Body)
        {
            $Params.Add('Body', $Body)
        }
    }

    process
    {
        $savedPreference = $ProgressPreference
        do
        {
            $ProgressPreference = 'SilentlyContinue'
            $Throttled = $false
            try
            {
                #$_result = Invoke-WebRequest @Params -ErrorAction Stop
                $_result = Invoke-RestMethod @Params -ErrorAction Stop
                $ProgressPreference = $savedPreference
                return $_result
            }

            catch
            {
                $CurrentError = $_
                $statusCode = $CurrentError.Exception.Response.StatusCode

                $iStatusCode = [int]$statusCode
                # Check to see if we had an intermitten network error
                if ($CurrentError.Exception -match 'decryption operation' `
                        -or $CurrentError.Exception -match 'unavailable' `
                        -or $iStatusCode -eq 504)
                {
                    $retryPeriod = ($retryCount * 5)
                    Write-Verbose "Transient error, sleeping for $retryPeriod seconds"
                    Start-Sleep -Seconds $retryPeriod
                    $Throttled = $true
                }
                elseif ($iStatusCode -eq 429 -or $iStatusCode -in 500..503)
                {
                    $retryPeriod = $CurrentError.Exception.Response.Headers['Retry-After']
                    if ($null -eq $retryPeriod)
                    {
                        $retryPeriod = ($retryCount * 5)
                    }
                    Write-Verbose "Received 429 throttle, sleeping for $retryPeriod seconds"
                    Start-Sleep -Seconds $retryPeriod
                    $Throttled = $true
                }
                # Add check for missing role assignment - that we can't fix
                elseif ($iStatusCode -in 401..403)
                {
                    $retryCount = $global:_MSGMaxRetry + 1
                    Write-Warning 'Attemptin re-auth'
                    $authHeader = SetAuthHeader -AuthMode $AuthMode
                    $Throttled = $true
                }

                if (-not $Throttled -or ($Throttled -and $retryCount++ -gt $global:_MSGMaxRetry))
                {
                    throw $CurrentError
                    <#
                    if ($null -ne $CurrentError.ErrorDetails.Message)
                    {
                        $JError = (ConvertFrom-Json $CurrentError.ErrorDetails.Message).error
                        $iStatusCode = $JError.code
                        $Message = $JError.Message
                    }

                    if ([string]::IsNullOrEmpty($Message))
                    {
                        $Message = $CurrentError.Exception.Message
                    }

                    $ProgressPreference = $savedPreference
                    $requestFailureData = [PSCustomObject][Ordered]@{
                        StatusCode      = $StatusCode.ToString()
                        Code            = $iStatusCode
                        Type            = $CurrentError.Exception.GetType().FullName
                        Message         = $Message
                        Description     = $CurrentError.Exception.Response.StatusDescription
                        RequestId       = $CurrentError.Exception.Response.Headers['request-id']
                        DateTimeStamp   = $CurrentError.Exception.Response.Headers['Date']
                        FullError       = $CurrentError
                        CallingFunction = (Get-PSCallStack)[1]
                    }
                    if ($null -ne ($diags = $CurrentError.Exception.Response.Headers['x-ms-ags-diagnostic']))
                    {
                        Add-Member -InputObject $requestFailureData -MemberType NoteProperty -Name Diagnostics -Value $diags
                    }
                    return $requestFailureData
                    #>
                }
            }
        } while ($Throttled)
    }
}
