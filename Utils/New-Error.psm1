function New-Error
{
    [CmdletBinding()]
    [OutputType([Management.Automation.ErrorRecord])]
    param(
        [Parameter(Mandatory = $true)]
        [Object]$ErrorObject,

        [Parameter(Mandatory = $false)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$AdditionalInfo,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Target
    )

    $callingFunction = [string](Get-PSCallStack)[1].Command
    $id = $ErrorObject.FullError.FullyQualifiedErrorId
    $msg = @{}

    if (-not [string]::IsNullOrEmpty($ErrorObject.FullError.ErrorDetails))
    {
        $innerMessage = (ConvertFrom-Json $ErrorObject.FullError.ErrorDetails.Message).'odata.error'.Message.value
    }
    if (-not [string]::IsNullOrEmpty($AdditionalInfo))
    {
        $emsg = "{0}: {1}" -f $AdditionalInfo, $ErrorObject.Message
    }
    else
    {
        $emsg = $ErrorObject.Message
    }
    $msg = "
`rStatusCode: $($ErrorObject.StatusCode)
`rCode: $($ErrorObject.code)
`rType: $($ErrorObject.Type)
`rMessage: $emsg
`rRequestId: $($ErrorObject.RequestId)
`rDateTimeStamp: $($ErrorObject.DateTimeStamp)"
    if ($null -ne $ErrorObject.diagnostics)
    {
        $msg += "`rx-ms-ags-diagnostic: $($ErrorObject.diagnostics.ServerInfo)"
    }

    if (-not $Target)
    {
        $Target = $callingFunction
    }
    $msg += "`rTarget: $Target"

    $exc = New-Object System.Exception $msg, $ErrorObject.FullError.Exception
    $ret = New-Object Management.Automation.ErrorRecord $exc, $id, "NotSpecified", $Target

    $ret
}
