#!/usr/bin/env python3

import re
import sys

def parse_variables_hcl(filename):
    """Parse variables.hcl file and extract variable definitions"""
    variables = []
    
    with open(filename, 'r') as f:
        content = f.read()
    
    # Find all variable blocks using regex
    variable_pattern = r'variable\s+"([^"]+)"\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}'
    matches = re.findall(variable_pattern, content, re.MULTILINE | re.DOTALL)
    
    for var_name, var_block in matches:
        # Parse the variable block
        default_match = re.search(r'default\s*=\s*(.+?)(?=\n|$)', var_block, re.MULTILINE)
        description_match = re.search(r'description\s*=\s*"([^"]*)"', var_block)
        sensitive_match = re.search(r'sensitive\s*=\s*true', var_block)
        
        default_val = default_match.group(1).strip() if default_match else None
        description = description_match.group(1) if description_match else ""
        is_sensitive = bool(sensitive_match)
        
        variables.append({
            'name': var_name,
            'default': default_val,
            'description': description,
            'sensitive': is_sensitive
        })
    
    return variables

def generate_template(variables):
    """Generate the variables template file"""
    # Sort variables alphabetically by name
    sorted_variables = sorted(variables, key=lambda x: x['name'])
    
    lines = []
    
    for var in sorted_variables:
        if var['sensitive']:
            value = '"<sensitive>"'
        elif var['default'] is None:
            value = '"<unknown>"'
        else:
            value = var['default']
        
        comment = f"  # {var['description']}" if var['description'] else ""
        lines.append(f"# {var['name']} = {value}{comment}")
    
    return '\n'.join(lines) + '\n'

if __name__ == "__main__":
    try:
        variables = parse_variables_hcl('variables.hcl')
        template_content = generate_template(variables)
        
        with open('variables.auto.hcl.template', 'w') as f:
            f.write(template_content)
            
        print(f"Generated template with {len(variables)} variables")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

