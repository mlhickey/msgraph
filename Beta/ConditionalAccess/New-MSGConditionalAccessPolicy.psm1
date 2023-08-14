function New-MSGConditionalAccessPolicy
{
    <#
    .SYNOPSIS
    Creates a new Azure Conditional Access policies

    .DESCRIPTION
    The New-MSGConditionalAccessPolicy cmdlet will create a new conditional access policiy based on the supplied conditionalAccessPolicy reource type(s)

    .PARAMETER PolicyObject
    A PowerShell object describing the conditionalAccessPolicy

    .PARAMETER PolicyString
    A JSON-formatted string describing the conditionalAccessPolicy

    .PARAMETER PolicyFile
    A file containing the JSON representation of one or more conditionalAccessPolicy items

    .LINK
     https://docs.microsoft.com/en-us/graph/api/conditionalaccessroot-post-policies?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Object',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Object describing the new policy.')]
        [object]$PolicyObject,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'JsonBody',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Object describing the new policy.')]
        [string]$PolicyString,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'File',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Object describing the new policy.')]
        [string]$PolicyFile
    )
    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'object'
            {
                try
                {
                    $policyBody = ConvertTo-Json $policyObject -Depth 10 
                }
                catch
                {
                    throw 'Provided object cannot be converted to JSON' 
                }
                break
            }

            'string'
            {
                try
                {
                    $policyObject = $PolicyString | ConvertFrom-Json 
                }
                catch
                {
                    throw 'Provided string does not appear to be valid JSON' 
                }
                break
            }

            'file'
            {
                try
                {
                    $policyBody = Get-Content -Raw $policyFile
                    $policyObject = $policyBody | ConvertFrom-Json
                }
                catch
                {
                    throw 'File content does not appear to be valid JSON' 
                }
                break
            }
        }

        Write-Verbose "Policy count: $($policyObject.Count)"

        foreach ($policy in $policyObject)
        {
            if ($PSCmdlet.ShouldProcess("$($Policy.displayName)", 'Add CA policy'))
            {
                New-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'identity/conditionalAccess/policies' -Object $policy
            }
        }
    }
}
