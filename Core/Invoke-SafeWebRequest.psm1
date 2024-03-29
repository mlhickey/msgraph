function  SetAuthHeader
{
    param(
        [string]$AuthMode
    )

    $script:MSGAuthInfo = Get-MSGConfig

    if ([string]::IsNullOrEmpty($AuthMode))
    {
        $AuthMode = $MSGAuthInfo.AuthType
    }

    $AuthParams = @{
        Tenant        = $MSGAuthInfo.TenantId
        ClientId      = $MSGAuthInfo.ApplicationId
        GraphEndPoint = $MSGAuthInfo.GraphUrl
        Authority     = $MSGAuthInfo.Authority
    }

    switch ($AuthMode.ToLower())
    {
        'user'
        {
            $authHeader = Get-UserAuthenticationResult @AuthParams -Debug:$DebugPreference -Verbose:$VerbosePreference
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
            $authHeader = Get-AppAuthenticationResult @AuthParams -Debug:$DebugPreference -Verbose:$VerbosePreference
            break
        }

        'delegated'
        {
            throw 'Delegated authentication deprecated'
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
        if ($null -eq $global:_MSGMaxRetry)
        {
            Set-Variable -Name _MSGMaxRetry -Scope Global -Value 5 -Option ReadOnly
        }

        $_result = $null
        $retryCount = 1

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

        Write-Debug "HTTP Method:`n$($Params.Method)`n`nAbsolute Uri:`n$($Params.Uri)`n`nBody: `n$body"
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

                $iStatusCode = $CurrentError.Exception.Response.StatusCode.value__
                # Check to see if we had an intermitten network error
                if ($CurrentError.Exception -match 'decryption operation' `
                        -or $iStatusCode -eq 504)
                {
                    $retryPeriod = ($retryCount * 60)
                    Write-Verbose "Transient error, sleeping for $retryPeriod seconds"
                    Start-Sleep -Seconds $retryPeriod
                    $Throttled = $true
                }
                elseif ($iStatusCode -eq 429 -or $iStatusCode -in 500..503)
                {
                    $retryPeriod = $CurrentError.Exception.Response.Headers['Retry-After']
                    if ($null -eq $retryPeriod)
                    {
                        #$retryPeriod = ($retryCount * 60)
                        $mPow = [math]::Pow(2, $Retrycount)
                        $retryPeriod = $mPow * $Delay
                    }
                    Write-Verbose "Received 429 throttle.  Pass $retryCount, sleeping for $retryPeriod seconds"
                    Start-Sleep -Seconds $retryPeriod
                    $Throttled = $true
                }
                # Add check for missing role assignment - that we can't fix
                elseif ($iStatusCode -in 401..403)
                {
                    Write-Verbose "Received $iStatusCode - getting new token"
                    Start-Sleep -Seconds ($retryCount * 60)
                    $authHeader = SetAuthHeader -AuthMode $AuthMode
                    $Headers['Authorization'] = $authHeader
                    $Throttled = $true
                }

                if (-not $Throttled -or ($Throttled -and $retryCount++ -gt $global:_MSGMaxRetry))
                {
                    if ($ErrorActionPreference = 'SilentlyContinue')
                    {
                        return $CurrentError
                    }
                    else
                    {
                        throw $CurrentError
                    }
                }
            }
        } while ($Throttled)
    }
}
