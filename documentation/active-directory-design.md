# Active Directory Design

## Overview

Northstar Business Solutions is modeled as a 200-employee organization using a single Active Directory forest and domain.

The environment was designed to separate users, endpoints, servers, privileged identities, service accounts, security groups, and disabled objects so that Group Policy, permissions, and administrative controls can be applied predictably.

## Domain Design

| Item | Configuration |
|---|---|
| Forest | `corp.northstar.test` |
| Domain | `corp.northstar.test` |
| NetBIOS Name | `NORTHSTAR` |
| Primary Domain Controller | `DC01` |
| DC01 IPv4 Address | `10.10.10.10` |
| Forest Functional Level | Windows Server 2025 |
| Domain Functional Level | Windows Server 2025 |
| DNS | Active Directory-integrated DNS |

The `.test` namespace was selected because the environment is an isolated lab and does not require a publicly resolvable production domain.

## Organizational Unit Design

Northstar uses a dedicated top-level OU rather than placing managed objects directly inside the default Active Directory containers.

```text
corp.northstar.test
└── Northstar
    ├── Users
    │   ├── Finance
    │   ├── Human Resources
    │   ├── Sales
    │   ├── Operations
    │   └── IT
    │
    ├── Workstations
    │   ├── Finance
    │   ├── Human Resources
    │   ├── Sales
    │   ├── Operations
    │   └── IT
    │
    ├── Servers
    ├── Groups
    ├── Admin Accounts
    ├── Service Accounts
    └── Disabled Objects
