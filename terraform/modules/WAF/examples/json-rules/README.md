# WAF JSON Rules Configuration

This example demonstrates how to use the WAF module with JSON rule files to define custom security rules. This approach allows you to:

- **Separate rule definitions from Terraform configuration**
- **Version control your security rules independently**
- **Share rule sets across multiple environments**
- **Use external tools to generate or validate rules**

## 📁 Directory Structure

```
json-rules/
├── terragrunt.hcl                    # Main Terragrunt configuration
├── README.md                         # This file
└── rules/                           # JSON rule files directory
    ├── country-blocking.json        # Geographic blocking rules
    ├── security-rules.json          # Security and threat protection
    └── rate-limiting.json           # Rate limiting rules
```

## 🔧 JSON Rule File Format

### Basic Structure

```json
{
  "description": "Rule set description",
  "version": "1.0",
  "rules": [
    {
      "name": "RuleName",
      "priority": 10,
      "action": "block|allow|count",
      "statement_type": "ip_set|geo_match|byte_match|rate_limit",
      "ip_set_arn": null,
      "country_codes": ["US", "CA"],
      "rate_limit": 1000,
      "aggregate_key_type": "IP",
      "field_to_match": "uri_path|query_string|body|single_header",
      "positional_constraint": "CONTAINS|STARTS_WITH|ENDS_WITH|EXACTLY_MATCHES",
      "search_string": "search text",
      "text_transformation": "LOWERCASE|UPPERCASE|NONE"
    }
  ]
}
```

### Rule Types and Required Fields

#### 1. **IP Set Rules** (`statement_type: "ip_set"`)
```json
{
  "name": "AllowOfficeIP",
  "priority": 1,
  "action": "allow",
  "statement_type": "ip_set",
  "ip_set_arn": null  // Uses module's whitelist/blacklist
}
```

#### 2. **Geographic Rules** (`statement_type: "geo_match"`)
```json
{
  "name": "BlockCameroon",
  "priority": 5,
  "action": "block", 
  "statement_type": "geo_match",
  "country_codes": ["CM", "CN", "RU"]
}
```

#### 3. **Byte Match Rules** (`statement_type: "byte_match"`)
```json
{
  "name": "BlockSQLInjection",
  "priority": 20,
  "action": "block",
  "statement_type": "byte_match",
  "field_to_match": "query_string",
  "positional_constraint": "CONTAINS",
  "search_string": "union select",
  "text_transformation": "LOWERCASE"
}
```

#### 4. **Rate Limit Rules** (`statement_type: "rate_limit"`)
```json
{
  "name": "APIRateLimit",
  "priority": 30,
  "action": "block",
  "statement_type": "rate_limit",
  "rate_limit": 1000,
  "aggregate_key_type": "IP"
}
```

## 🚀 Usage Examples

### Basic Configuration

```hcl
waf = {
  create_waf = true
  name       = "my-waf"
  
  # Load rules from JSON files
  json_rule_files = [
    "${path.module}/rules/security.json",
    "${path.module}/rules/geo-blocking.json"
  ]
  
  # IP whitelist for rules that reference it
  ip_sets = {
    create_whitelist = true
    whitelist_ips    = ["10.113.40.30/32"]
  }
}
```

### Multiple Rule Files

```hcl
json_rule_files = [
  "./rules/country-blocking.json",      # Geographic rules
  "./rules/security-rules.json",       # Security patterns  
  "./rules/rate-limiting.json",        # Rate limiting
  "./rules/custom-application.json"    # App-specific rules
]
```

### Environment-Specific Rules

```hcl
# Development
json_rule_files = [
  "./rules/common/security.json",
  "./rules/dev/permissive.json"
]

# Production  
json_rule_files = [
  "./rules/common/security.json",
  "./rules/prod/strict.json",
  "./rules/prod/compliance.json"
]
```

## 📝 Rule Examples

### 1. **Country Blocking Rules** (`country-blocking.json`)

```json
{
  "description": "Block traffic from high-risk countries",
  "rules": [
    {
      "name": "AllowOfficeIP",
      "priority": 1,
      "action": "allow",
      "statement_type": "ip_set",
      "ip_set_arn": null
    },
    {
      "name": "BlockHighRiskCountries", 
      "priority": 10,
      "action": "block",
      "statement_type": "geo_match",
      "country_codes": ["CM", "CN", "RU", "KP", "IR"]
    }
  ]
}
```

### 2. **Security Rules** (`security-rules.json`)

```json
{
  "description": "Common web application security rules",
  "rules": [
    {
      "name": "BlockSQLInjection",
      "priority": 20,
      "action": "block", 
      "statement_type": "byte_match",
      "field_to_match": "query_string",
      "positional_constraint": "CONTAINS",
      "search_string": "union select",
      "text_transformation": "LOWERCASE"
    },
    {
      "name": "BlockXSSAttempts",
      "priority": 21,
      "action": "block",
      "statement_type": "byte_match", 
      "field_to_match": "body",
      "positional_constraint": "CONTAINS",
      "search_string": "<script",
      "text_transformation": "LOWERCASE"
    },
    {
      "name": "BlockPathTraversal",
      "priority": 22,
      "action": "block",
      "statement_type": "byte_match",
      "field_to_match": "uri_path", 
      "positional_constraint": "CONTAINS",
      "search_string": "../",
      "text_transformation": "NONE"
    }
  ]
}
```

### 3. **Rate Limiting Rules** (`rate-limiting.json`)

```json
{
  "description": "API and endpoint rate limiting",
  "rules": [
    {
      "name": "GlobalAPILimit",
      "priority": 30,
      "action": "block",
      "statement_type": "rate_limit",
      "rate_limit": 2000,
      "aggregate_key_type": "IP"
    },
    {
      "name": "LoginEndpointLimit", 
      "priority": 31,
      "action": "block",
      "statement_type": "rate_limit",
      "rate_limit": 20,
      "aggregate_key_type": "IP",
      "field_to_match": "uri_path",
      "positional_constraint": "EXACTLY_MATCHES",
      "search_string": "/login"
    }
  ]
}
```

## 🔄 Rule Priority Management

Rules are evaluated in **priority order** (lower number = higher priority):

```
Priority 1-9:    Allow/Whitelist rules
Priority 10-19:  Geographic blocking  
Priority 20-29:  Security pattern matching
Priority 30-39:  Rate limiting
Priority 40-99:  Application-specific rules
Priority 100+:   AWS Managed Rules
```

## ⚡ Advanced Features

### Dynamic IP Set References

```json
{
  "name": "AllowTrustedIPs",
  "statement_type": "ip_set",
  "ip_set_arn": null  // Automatically uses module's whitelist
}

{
  "name": "BlockKnownBadIPs", 
  "statement_type": "ip_set",
  "ip_set_arn": "arn:aws:wafv2:region:account:ipset/..."  // Custom IP set
}
```

### Complex Byte Matching

```json
{
  "name": "BlockUserAgent",
  "statement_type": "byte_match",
  "field_to_match": "single_header",
  "positional_constraint": "CONTAINS", 
  "search_string": "BadBot",
  "text_transformation": "LOWERCASE"
}
```

### Scoped Rate Limiting

```json
{
  "name": "CountrySpecificLimit",
  "statement_type": "rate_limit", 
  "rate_limit": 100,
  "aggregate_key_type": "IP",
  "scope_down_statement": {
    "type": "geo_match",
    "country_codes": ["CN", "RU"]
  }
}
```

## 🛠️ Development Workflow

### 1. **Create Rule Files**
```bash
mkdir rules
touch rules/security.json
touch rules/geo-blocking.json  
touch rules/rate-limiting.json
```

### 2. **Validate JSON**
```bash
# Check JSON syntax
jq . rules/security.json

# Validate all rule files
for file in rules/*.json; do
  echo "Validating $file..."
  jq . "$file" > /dev/null && echo "✅ Valid" || echo "❌ Invalid"
done
```

### 3. **Test Rules** 
```bash
# Plan with new rules
terragrunt plan

# Apply changes
terragrunt apply

# Monitor in CloudWatch
aws wafv2 get-sampled-requests \
  --web-acl-arn "your-waf-arn" \
  --rule-metric-name "BlockSQLInjection" \
  --scope REGIONAL \
  --time-window StartTime=2024-01-01T00:00:00Z,EndTime=2024-01-02T00:00:00Z
```

## 📊 Monitoring and Debugging

### CloudWatch Metrics

Monitor rule effectiveness:

- `AWS/WAFV2/AllowedRequests`
- `AWS/WAFV2/BlockedRequests` 
- `AWS/WAFV2/CountedRequests`

### Log Analysis

JSON rules generate detailed logs:

```json
{
  "action": "BLOCK",
  "terminatingRuleId": "BlockSQLInjection",
  "terminatingRuleType": "REGULAR",
  "httpRequest": {
    "uri": "/search?q=1' UNION SELECT password FROM users--",
    "method": "GET"
  }
}
```

## 🚨 Security Best Practices

1. **Version Control**: Always version your JSON rule files
2. **Testing**: Test rules in development before production
3. **Monitoring**: Set up alerts for unexpected blocking patterns
4. **Documentation**: Document the purpose of each rule
5. **Review**: Regularly review and update security rules
6. **Backup**: Keep backups of working rule configurations

## 🐛 Troubleshooting

### Common Issues

**1. JSON Syntax Errors**
```bash
Error: Invalid JSON syntax in rules/security.json
```
**Solution**: Validate JSON with `jq . file.json`

**2. Missing Required Fields**
```bash
Error: statement_type is required for all rules
```
**Solution**: Ensure all rules have required fields for their type

**3. Priority Conflicts**
```bash
Error: Multiple rules with same priority
```
**Solution**: Ensure each rule has unique priority number

**4. File Path Issues**
```bash
Error: file() function cannot read ./rules/security.json
```
**Solution**: Use absolute paths or verify file exists

### Validation Script

```bash
#!/bin/bash
# validate-rules.sh

echo "🔍 Validating WAF JSON rule files..."

for file in rules/*.json; do
  if [[ -f "$file" ]]; then
    echo "Checking $file..."
    
    # Check JSON syntax
    if ! jq . "$file" > /dev/null 2>&1; then
      echo "❌ Invalid JSON syntax: $file"
      continue
    fi
    
    # Check required structure
    if ! jq '.rules[]' "$file" > /dev/null 2>&1; then
      echo "❌ Missing rules array: $file" 
      continue
    fi
    
    # Check rule fields
    missing_fields=$(jq -r '.rules[] | select(.name == null or .priority == null or .action == null or .statement_type == null) | .name // "unnamed"' "$file")
    
    if [[ -n "$missing_fields" ]]; then
      echo "❌ Rules missing required fields: $file"
      echo "   Rules: $missing_fields"
      continue
    fi
    
    echo "✅ Valid: $file"
  fi
done

echo "✨ Validation complete!"
```

## 📚 Additional Resources

- [AWS WAF Rule Statement Types](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type.html)
- [WAF Rule Actions](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-action.html)  
- [JSON Schema Validation](https://json-schema.org/)
- [jq Manual](https://stedolan.github.io/jq/manual/)

This JSON rules system provides flexibility and maintainability for complex WAF configurations while keeping your Terraform code clean and focused.