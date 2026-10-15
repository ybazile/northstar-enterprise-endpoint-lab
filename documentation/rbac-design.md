# RBAC and Security Group Design

## Overview

Northstar Business Solutions uses a role-based access control model built around Active Directory security groups rather than assigning permissions directly to individual users.

The design follows the **AGDLP** model:

`Accounts → Global Groups → Domain Local Groups → Permissions`

This provides a scalable way to manage access as employees join, change departments, or leave the organization.

## Why AGDLP

Directly assigning permissions to individual users creates administrative overhead and makes access reviews difficult.

Instead, Northstar separates:

- **Who the user is**
- **What role or department they belong to**
- **What resource permission is required**

Example:

```text
Finance Employee
      ↓
GG-FIN-Users
      ↓
DL-FIN-Share-RW
      ↓
Finance Resource
