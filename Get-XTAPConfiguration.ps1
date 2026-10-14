# ============================================================
# Get-XTAPConfiguration.ps1
#
# Read-only Microsoft 365 XTAP configuration checker.
#
# - Enter a partner domain
# - Resolves the Microsoft Entra Tenant ID
# - Checks for an existing XTAP partner
# - Lists configured Microsoft 365 capabilities
# ============================================================

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Microsoft 365 XTAP Configuration Check" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Required Graph scopes
# ------------------------------------------------------------

$RequiredScopes = @(
    "Policy.Read.All"
    "Policy.ReadWrite.CrossTenantAccess"
    "Policy.ReadWrite.CrossTenantCapability"
)

# ------------------------------------------------------------
# Check Microsoft Graph connection
# ------------------------------------------------------------

Write-Host "Checking Microsoft Graph connection..." -ForegroundColor Yellow

$GraphContext = Get-MgContext -ErrorAction SilentlyContinue

if ($null -eq $GraphContext) {

    Write-Host "No existing Graph connection found." -ForegroundColor Yellow
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow

    try {

        Connect-MgGraph `
            -Scopes $RequiredScopes `
            -ContextScope Process `
            -NoWelcome

        $GraphContext = Get-MgContext
    }
    catch {

        Write-Host ""
        Write-Host "ERROR: Unable to connect to Microsoft Graph." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit
    }
}
else {

    Write-Host "Existing Microsoft Graph connection found." -ForegroundColor Green
    Write-Host "Account : $($GraphContext.Account)"
    Write-Host "Tenant  : $($GraphContext.TenantId)"
}

Write-Host ""

# ------------------------------------------------------------
# Get partner domain
# ------------------------------------------------------------

$PartnerDomain = Read-Host "Enter partner domain (example: contoso.com)"

if ([string]::IsNullOrWhiteSpace($PartnerDomain)) {

    Write-Host "ERROR: A domain name is required." -ForegroundColor Red
    exit
}

$PartnerDomain = $PartnerDomain.Trim().ToLower()

# ------------------------------------------------------------
# Resolve domain to Microsoft Entra Tenant ID
# ------------------------------------------------------------

Write-Host ""
Write-Host "Resolving tenant for $PartnerDomain..." -ForegroundColor Yellow

$OIDCUri = "https://login.microsoftonline.com/$PartnerDomain/v2.0/.well-known/openid-configuration"

try {

    $OIDC = Invoke-RestMethod `
        -Method GET `
        -Uri $OIDCUri `
        -ErrorAction Stop

    $PartnerTenantId = ($OIDC.issuer -split "/")[3]
}
catch {

    Write-Host ""
    Write-Host "ERROR: Unable to resolve Microsoft Entra tenant." -ForegroundColor Red
    Write-Host "Domain: $PartnerDomain"
    exit
}

Write-Host ""
Write-Host "Partner Domain    : $PartnerDomain" -ForegroundColor Green
Write-Host "Partner Tenant ID : $PartnerTenantId" -ForegroundColor Green

# ------------------------------------------------------------
# XTAP Graph URLs
# ------------------------------------------------------------

$PartnerUri = "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/$PartnerTenantId"

$CapabilitiesUri = "$PartnerUri/m365Capabilities"

# ------------------------------------------------------------
# Check XTAP partner
# ------------------------------------------------------------

Write-Host ""
Write-Host "Checking XTAP partner configuration..." -ForegroundColor Yellow

try {

    $PartnerPolicy = Invoke-MgGraphRequest `
        -Method GET `
        -Uri $PartnerUri `
        -ErrorAction Stop
}
catch {

    Write-Host ""
    Write-Host "NO XTAP PARTNER CONFIGURATION FOUND" -ForegroundColor Red

    Write-Host ""
    Write-Host "Domain    : $PartnerDomain"
    Write-Host "Tenant ID : $PartnerTenantId"

    exit
}

Write-Host "XTAP partner found." -ForegroundColor Green

# ------------------------------------------------------------
# Get Microsoft 365 capabilities
# ------------------------------------------------------------

Write-Host ""
Write-Host "Retrieving Microsoft 365 XTAP capabilities..." -ForegroundColor Yellow

try {

    $Result = Invoke-MgGraphRequest `
        -Method GET `
        -Uri $CapabilitiesUri `
        -ErrorAction Stop

    $Capabilities = @($Result.value)
}
catch {

    Write-Host ""
    Write-Host "ERROR: Unable to retrieve M365 XTAP capabilities." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit
}

# ------------------------------------------------------------
# Display result
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " XTAP CONFIGURATION" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Partner Domain    : $PartnerDomain"
Write-Host "Partner Tenant ID : $PartnerTenantId"

if ($Capabilities.Count -eq 0) {

    Write-Host ""
    Write-Host "No Microsoft 365 XTAP capabilities configured." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Configured Capabilities" -ForegroundColor Green
Write-Host "-----------------------" -ForegroundColor Green

# ------------------------------------------------------------
# Build simple results
# ------------------------------------------------------------

$Output = foreach ($Capability in $Capabilities) {

    $IncludedScopes = @()

    foreach ($Scope in @($Capability.inboundAccess.resourceScopes.included)) {

        if ($null -ne $Scope.resourceId) {

            $IncludedScopes += "$($Scope.resourceId)/$($Scope.resourceType)"
        }
    }

    if ($IncludedScopes.Count -gt 0) {

        $IncludedText = $IncludedScopes -join ", "
    }
    else {

        $IncludedText = "None"
    }

    [PSCustomObject]@{

        Capability = $Capability.name

        Allowed = $Capability.inboundAccess.isAllowed

        Scope = $IncludedText

        LastModified = $Capability.lastModifiedDateTime
    }
}

# ------------------------------------------------------------
# Display table
# ------------------------------------------------------------

Write-Host ""

$Output |
    Sort-Object Capability |
    Format-Table  Capability,
        Allowed,
        Scope,
        LastModified `
        -AutoSize

# ------------------------------------------------------------
# Detailed output
# ------------------------------------------------------------

Write-Host ""
Write-Host "Detailed Configuration" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

foreach ($Item in ($Output | Sort-Object Capability)) {

    Write-Host ""
    Write-Host "Capability    : $($Item.Capability)" -ForegroundColor Yellow
    Write-Host "Allowed       : $($Item.Allowed)"
    Write-Host "Scope         : $($Item.Scope)"
    Write-Host "Last Modified : $($Item.LastModified)"
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " XTAP configuration check complete" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""