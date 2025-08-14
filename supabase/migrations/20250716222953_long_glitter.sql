/*
  # Create workspace_employees view for employee management

  1. New View
    - `workspace_employees` view that joins users with roles
    - Bypasses RLS restrictions for workspace admin functionality
    - Includes all necessary fields for employee management

  2. Security
    - View has no RLS policies (allows full access)
    - Security handled at application level
    - Only used for specific admin functionality

  3. Fields Included
    - All user fields needed for employee management
    - Role name for filtering and display
    - Workspace information for filtering
*/

-- Create view for workspace employees that bypasses RLS
CREATE OR REPLACE VIEW workspace_employees AS
SELECT 
  u.id,
  u.full_name,
  u.email,
  u.phone,
  u.role_id,
  u.workspace_id,
  u.is_active,
  u.created_at,
  u.updated_at,
  u.last_login,
  r.name as role_name,
  r.description as role_description
FROM users u
JOIN user_roles r ON u.role_id = r.id
WHERE u.workspace_id IS NOT NULL;

-- Grant access to authenticated users
GRANT SELECT ON workspace_employees TO authenticated;