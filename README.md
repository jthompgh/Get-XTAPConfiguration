# Get-XTAPConfiguration

A simple, read-only PowerShell utility for reviewing Microsoft 365 Cross-Tenant Access Policy (XTAP) configuration for a partner tenant.

The script accepts a partner domain name, resolves the domain to its Microsoft Entra tenant ID, verifies that an XTAP partner configuration exists, and displays the Microsoft 365 capabilities configured for that partner.

## Features

- Resolves a Microsoft 365 domain to its Microsoft Entra tenant ID
- Detects an existing Microsoft Graph connection
- Connects to Microsoft Graph when required
- Verifies that a Cross-Tenant Access Policy partner exists
- Retrieves configured Microsoft 365 XTAP capabilities
- Displays whether each capability is allowed
- Displays the configured resource scope
- Displays the last-modified timestamp returned by Microsoft Graph
- Makes no configuration changes

## Capabilities

Depending on the XTAP configuration, the script can report capabilities such as:

- `crossTenantCalendarAvailabilityBasic`
- `crossTenantCalendarAvailabilityLimitedDetails`
- `crossTenantCalendarSharingFreeBusySimple`
- `crossTenantCalendarSharingFreeBusyDetail`
- `crossTenantCalendarSharingFreeBusyReviewer`
- `crossTenantMailTipsLimited`
- `crossTenantMailTipsAll`

The script reports the capabilities returned by Microsoft Graph. It does not create, modify, enable, disable, or remove them.

## Requirements

- Windows PowerShell or PowerShell 7
- Microsoft Graph PowerShell SDK
- An account with permission to read the applicable Microsoft Graph cross-tenant access policy configuration

The script uses these Microsoft Graph scopes:

- `Policy.Read.All`
- `Policy.ReadWrite.CrossTenantAccess`
- `Policy.ReadWrite.CrossTenantCapability`

These scopes match the configuration/testing environment for which the script was developed. The script itself performs read-only Graph requests.

## Installation

Clone or download this repository and open PowerShell in the script directory.

Verify that Microsoft Graph PowerShell is available:

`Get-Command Connect-MgGraph`

If Microsoft Graph PowerShell is not installed, install the appropriate Microsoft Graph PowerShell SDK modules before running the script.

## Usage

Run:

`.\Get-XTAPConfiguration.ps1`

If a Microsoft Graph session with the required scopes already exists, the script reuses the existing connection.

Otherwise, the script attempts to establish a Microsoft Graph connection.

When prompted, enter the partner's verified Microsoft 365 domain, for example:

`contoso.com`

The script resolves the domain to its Microsoft Entra tenant ID and checks the corresponding XTAP partner configuration.

## Example Output

A configured partner might return capabilities similar to:

```text
Capability                                           Allowed Scope
----------                                           ------- -----
crossTenantCalendarAvailabilityLimitedDetails       True    All/user
crossTenantCalendarSharingFreeBusyReviewer           True    All/user
crossTenantMailTipsAll                               True    All/user
```

The actual results depend on the Microsoft 365 Cross-Tenant Access Policy configuration in the tenant where the script is run.

## What the Script Does

The script performs the following sequence:

1. Checks for the Microsoft Graph PowerShell commands.
2. Checks for an existing Microsoft Graph connection.
3. Prompts for the external partner domain.
4. Uses Microsoft identity OpenID metadata to resolve the domain to a tenant ID.
5. Queries the Microsoft Graph Cross-Tenant Access Policy partner endpoint.
6. Verifies that an XTAP relationship exists for the resolved tenant.
7. Queries the partner's `m365Capabilities`.
8. Displays the capabilities, allowed state, scope, and last-modified value.

## Read-Only Design

`Get-XTAPConfiguration.ps1` is intended as a discovery and validation utility.

The script does **not**:

- Create an XTAP partner relationship
- Add Microsoft 365 capabilities
- Modify capability scopes
- Enable or disable capabilities
- Remove XTAP configuration
- Modify Exchange Online Organization Relationships
- Modify Exchange Online Sharing Policies

## Troubleshooting

### InteractiveBrowserCredential authentication failed

If you already connected to Microsoft Graph successfully, run the script from the same PowerShell session.

For example:

`Connect-MgGraph -Scopes "Policy.Read.All,Policy.ReadWrite.CrossTenantAccess,Policy.ReadWrite.CrossTenantCapability" -ContextScope Process`

Then run:

`.\Get-XTAPConfiguration.ps1`

The script checks the current Microsoft Graph context and can reuse an existing connection.

### Partner domain resolves, but no XTAP configuration is found

This indicates that the domain could be resolved to a Microsoft Entra tenant ID but the script could not retrieve a corresponding Cross-Tenant Access Policy partner using that tenant ID.

Verify the configured partners separately if necessary.

### XTAP partner exists but no capabilities are returned

An XTAP partner relationship and Microsoft 365 capabilities are separate objects. The script reports when the partner exists but no Microsoft 365 capabilities are returned.

## Microsoft Documentation

For Microsoft documentation covering migration of Free/Busy, Calendar Sharing, and MailTips to Microsoft 365 Cross-Tenant Access Policies, see:

**Migrate to Microsoft 365 Cross-Tenant Access Policy for sharing Free/Busy, Calendars, and MailTips**

https://learn.microsoft.com/en-us/exchange/sharing/migrate-to-m365-xtap

## Disclaimer

This project is an independent utility and is not an official Microsoft product.

Always validate configuration changes against current Microsoft documentation and test changes appropriately before applying them to production environments.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
