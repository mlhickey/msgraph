function BuildUserANRSearchString
{
    param(
        [ValidateNotNullOrEmpty()]
        [string]$searchString
    )

    # Escape any single quotes in searchstring
    $str = $searchString.Replace("'", "''")
    $result = "userPrincipalName eq '{0}' or (mailNickName eq '{0}' or (mail eq '{0}' or (jobTitle eq '{0}' or (displayName eq '{0}' or (startswith(displayName,'{0}') or (startswith(userPrincipalName,'{0}') or (department eq '{0}' or (country eq '{0}' or city eq '{0}'))))))))" -f $str
    return $result
}

