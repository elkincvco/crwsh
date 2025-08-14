/*
  # Fix users table RLS policy for employee creation

  1. Security Changes
    - Drop existing restrictive policy
    - Add comprehensive INSERT policy for admins
    - Ensure workspace admins can create employees in their workspace
    - Ensure super admins can create employees anywhere

  2. Policy Logic
    - Uses proper role checking with JOIN operations
    - Validates workspace permissions for workspace_admin
    - Allows unrestricted access for super_admin
*/

-- Drop existing policies that might be conflicting
DROP POLICY IF EXISTS "basic_user_access" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "users_delete_policy" ON users;

-- Create comprehensive INSERT policy for admins to create employees
CREATE POLICY "admins_can_insert_users"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Super admin can create users anywhere
    auth.uid() IN (
      SELECT u.id 
      FROM users u 
      JOIN user_roles r ON u.role_id = r.id 
      WHERE r.name = 'super_admin'
    )
    OR
    -- Workspace admin can create users in their workspace
    (
      auth.uid() IN (
        SELECT u.id 
        FROM users u 
        JOIN user_roles r ON u.role_id = r.id 
        WHERE r.name = 'workspace_admin'
      )
      AND
      workspace_id IN (
        SELECT u.workspace_id 
        FROM users u 
        WHERE u.id = auth.uid()
      )
    )
  );

-- Create SELECT policy for reading user data
CREATE POLICY "users_can_read_data"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    -- Users can read their own data
    id = auth.uid()
    OR
    -- Super admin can read all users
    auth.uid() IN (
      SELECT u.id 
      FROM users u 
      JOIN user_roles r ON u.role_id = r.id 
      WHERE r.name = 'super_admin'
    )
    OR
    -- Workspace admin can read users in their workspace
    (
      auth.uid() IN (
        SELECT u.id 
        FROM users u 
        JOIN user_roles r ON u.role_id = r.id 
        WHERE r.name = 'workspace_admin'
      )
      AND
      workspace_id IN (
        SELECT u.workspace_id 
        FROM users u 
        WHERE u.id = auth.uid()
      )
    )
  );

-- Create UPDATE policy for modifying user data
CREATE POLICY "users_can_update_data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (
    -- Users can update their own data
    id = auth.uid()
    OR
    -- Super admin can update all users
    auth.uid() IN (
      SELECT u.id 
      FROM users u 
      JOIN user_roles r ON u.role_id = r.id 
      WHERE r.name = 'super_admin'
    )
    OR
    -- Workspace admin can update users in their workspace
    (
      auth.uid() IN (
        SELECT u.id 
        FROM users u 
        JOIN user_roles r ON u.role_id = r.id 
        WHERE r.name = 'workspace_admin'
      )
      AND
      workspace_id IN (
        SELECT u.workspace_id 
        FROM users u 
        WHERE u.id = auth.uid()
      )
    )
  )
  WITH CHECK (
    -- Same conditions for WITH CHECK
    id = auth.uid()
    OR
    auth.uid() IN (
      SELECT u.id 
      FROM users u 
      JOIN user_roles r ON u.role_id = r.id 
      WHERE r.name = 'super_admin'
    )
    OR
    (
      auth.uid() IN (
        SELECT u.id 
        FROM users u 
        JOIN user_roles r ON u.role_id = r.id 
        WHERE r.name = 'workspace_admin'
      )
      AND
      workspace_id IN (
        SELECT u.workspace_id 
        FROM users u 
        WHERE u.id = auth.uid()
      )
    )
  );