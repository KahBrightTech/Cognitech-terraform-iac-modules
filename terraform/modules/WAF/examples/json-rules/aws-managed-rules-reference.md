# AWS Managed WAF Rules Reference

This file lists all available AWS managed rule groups for WAF v2, based on the AWS Management Console as of November 2025.

## 🆓 **Free Rule Groups**
*No additional charges beyond standard AWS WAF service fees*

| Console Name | Terraform Name | Capacity | Description |
|--------------|----------------|----------|-------------|
| **Admin protection** | `AWSManagedRulesAdminProtectionRuleSet` | 100 | Block external access to exposed admin pages. Useful for third-party software protection. |
| **Amazon IP reputation list** | `AWSManagedRulesAmazonIpReputationList` | 25 | Rules based on Amazon threat intelligence to block sources associated with bots or threats. |
| **Anonymous IP list** | `AWSManagedRulesAnonymousIpList` | 50 | Block requests from VPNs, proxies, Tor nodes, and hosting providers that obfuscate viewer identity. |
| **Core rule set** | `AWSManagedRulesCommonRuleSet` | 700 | General web application protection against OWASP vulnerabilities. **Most commonly used.** |
| **Known bad inputs** | `AWSManagedRulesKnownBadInputsRuleSet` | 200 | Block request patterns known to be invalid and associated with vulnerability exploitation. |
| **Linux operating system** | `AWSManagedRulesLinuxRuleSet` | 200 | Protection against Linux-specific vulnerabilities, including LFI attacks. |
| **PHP application** | `AWSManagedRulesPHPRuleSet` | 100 | Block request patterns targeting PHP vulnerabilities, including unsafe PHP functions. |
| **POSIX operating system** | `AWSManagedRulesUnixRuleSet` | 100 | Protection against POSIX/POSIX-like OS vulnerabilities, including LFI attacks. |
| **SQL database** | `AWSManagedRulesSQLiRuleSet` | 200 | Block SQL injection attacks and unauthorized database queries. |
| **Windows operating system** | `AWSManagedRulesWindowsRuleSet` | 200 | Protection against Windows-specific vulnerabilities (e.g., PowerShell commands). |
| **WordPress application** | `AWSManagedRulesWordPressRuleSet` | 100 | Block request patterns targeting WordPress-specific vulnerabilities. |

## 💰 **Paid Rule Groups**
*Additional subscription and usage fees apply*

| Console Name | Terraform Name | Capacity | Monthly Fee | Description |
|--------------|----------------|----------|-------------|-------------|
| **Account creation fraud prevention** | `AWSManagedRulesACFPRuleSet` | 50 | $10/month | Protect against fraudulent account creation and sign-up bonuses abuse. |
| **Account takeover prevention** | `AWSManagedRulesATPRuleSet` | 50 | $10/month | Protect login pages against stolen credentials, credential stuffing, and brute force attacks. |
| **AntiDDoS Protection for Layer 7** | `AWSManagedRulesAntiDDoSRuleSet` | 50 | $20/month | Protection against Layer 7 DDoS attacks targeting the application layer. |
| **Bot Control** | `AWSManagedRulesBotControlRuleSet` | 50 | $10/month+ | Advanced bot protection with two levels: Common ($10/month) and Targeted ($10/month base). |

## 🎯 **Recommended Combinations**

### **Basic Protection (Free)**
```hcl
managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    priority        = 100
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesKnownBadInputsRuleSet"
    priority        = 110
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  }
]
```

### **Enhanced Security (Free)**
```hcl
managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    priority        = 100
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesKnownBadInputsRuleSet"
    priority        = 110
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesSQLiRuleSet"
    priority        = 120
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesAmazonIpReputationList"
    priority        = 130
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  }
]
```

### **Linux Web Application (Free)**
```hcl
managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    priority        = 100
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesLinuxRuleSet"
    priority        = 110
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesSQLiRuleSet"
    priority        = 120
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  }
]
```

### **WordPress Site (Free)**
```hcl
managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    priority        = 100
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesWordPressRuleSet"
    priority        = 110
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesSQLiRuleSet"
    priority        = 120
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  }
]
```

### **High-Security E-commerce (Paid)**
```hcl
managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    priority        = 100
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesBotControlRuleSet"
    priority        = 110
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesATPRuleSet"
    priority        = 120
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesACFPRuleSet"
    priority        = 130
    vendor_name     = "AWS"
    exclude_rules   = []
    override_action = "none"
  }
]
```

## 🔧 **Usage Notes**

### **Priority Guidelines**
- **1-99**: Custom/JSON rules (IP whitelisting, geo-blocking, etc.)
- **100-199**: AWS managed rule groups
- **200-299**: Rate limiting rules
- **300+**: Additional custom rules

### **Capacity Planning**
- Each Web ACL has a capacity limit of **1,500 WCU** (WAF Capacity Units)
- Plan your rule groups to stay within this limit
- Core rule set uses 700 WCU (nearly half the limit)

### **Override Actions**
- **`none`**: Apply the rule group's actions (recommended)
- **`count`**: Count requests but don't block (monitoring mode)

### **Cost Considerations**
- **Free rules**: Only standard WAF charges ($0.60 per million requests)
- **Paid rules**: Additional monthly fees + usage-based pricing
- **Bot Control**: Tiered pricing based on protection level

## 📚 **Additional Resources**

- [AWS WAF Managed Rules Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html)
- [AWS WAF Pricing](https://aws.amazon.com/waf/pricing/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🗓️ **Last Updated**
November 17, 2025 - Based on AWS Management Console