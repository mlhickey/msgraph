function Set-MSGUser
{
    <#
    .SYNOPSIS
    Get group information

    .DESCRIPTION
    The Set-MSGUser cmdlet sets one or more properties for the specified user.

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD.  This parameter is also aliased to ObjectId for named pipeline processing

    .PARAMETER PasswordProfile
    Specifies the password profile information required to set/reset a password.  A PasswordProfile object must contain two elements:
        Passwrd: <string value>
        ForceChangePasswordNextLogin: <bool>


    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-update?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams', '')]
    [CmdletBinding()]
    [Alias("Set-MSGraphUser")]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the user.")]
        [Alias("ObjectId")]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [bool]$AccountEnabled,

        [Parameter(Mandatory = $false,
            HelpMessage = "Age group: Adult, Minor or NotAdult")]
        [ValidateSet(
            "adult",
            "minor",
            "notadult"
        )]
        [object]$AgeGroup,

        [Parameter(Mandatory = $false)]
        [string[]]$BusinessPhones,

        [Parameter(Mandatory = $false)]
        [string]$City,

        [Parameter(Mandatory = $false)]
        [ValidateLength(0, 64)]
        [string]$CompanyName,

        [Parameter(Mandatory = $false)]
        [string]$Country,

        [Parameter(Mandatory = $false)]
        [object]$CreatedDateTime,

        [Parameter(Mandatory = $false)]
        [string]$Department,

        [Parameter(Mandatory = $false)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string]$EmployeeId,

        [Parameter(Mandatory = $false)]
        [string]$EmployeeType,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute1,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute2,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute3,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute4,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute5,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute6,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute7,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute8,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute9,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute10,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute11,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute12,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute13,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute14,

        [Parameter(Mandatory = $false)]
        [string]$ExtensionAttribute15,

        [Parameter(Mandatory = $false)]
        [string]$FaxNumber,

        [Parameter(Mandatory = $false)]
        [string]$GivenName,

        [Parameter(Mandatory = $false)]
        [string[]]$Identities,

        [Parameter(Mandatory = $false)]
        [string[]]$ImAddresses,

        [Parameter(Mandatory = $false)]
        [string]$JobTitle,

        [Parameter(Mandatory = $false)]
        [string]$Mail,

        [Parameter(Mandatory = $false)]
        [string]$MailNickname,

        [Parameter(Mandatory = $false)]
        [string]$MobilePhone,

        [Parameter(Mandatory = $false)]
        [string]$OfficeLocation,

        [Parameter(Mandatory = $false)]
        [string[]]$OtherMails,

        [Parameter(Mandatory = $false)]
        [string]$OnPremisesImmutableId,

        [Parameter(Mandatory = $false)]
        [object]$PasswordProfile,

        [Parameter(Mandatory = $false)]
        [string]$PostalCode,

        [Parameter(Mandatory = $false)]
        [string]$PreferredLanguage,

        [Parameter(Mandatory = $false)]
        [string]$State,

        [Parameter(Mandatory = $false)]
        [string]$StreetAddress,

        [Parameter(Mandatory = $false)]
        [string]$Surname,

        [Parameter(Mandatory = $false)]
        [ValidateLength(2, 2)]
        [string]$UsageLocation,

        [Parameter(Mandatory = $false)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [string]$UserType
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }

        $null = $PSBoundParameters.Remove("Id")
        $patchBody = @{}
        $onPremisesExtensionAttributes = @{}
        $eaCount = 0

        foreach ($psbp in $PSBoundParameters.GetEnumerator())
        {
            $inputObject = $patchBody
            $Name = camelCase $psbp.key
            $Value = $psbp.Value
            if ([string]::IsNullOrEmpty($Value)) { $Value = $Null }
            if ($Name -match "extensionAttribute\d*")
            {
                $inputObject = $onPremisesExtensionAttributes
                $eaCount++
            }
            $inputObject.Add($name, $value)
        }
        if ($eaCount -gt 0)
        {
            $patchBody.Add("onPremisesExtensionAttributes", $onPremisesExtensionAttributes)
        }
    }

    process
    {
        $id = [uri]::EscapeDataString($id)
        Set-MSGObject -Type "users/$id" -Method PATCH -Body $patchBody
    }
}
