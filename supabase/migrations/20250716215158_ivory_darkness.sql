/*
  # Fix RLS policies for workspace admin access to users

  1. Problem Identified
    - Workspace admins can only see their own user record
    - Cannot see other employees in their workspace
    - Current policy: `USING (auth.uid() = id)` only allows self-access

  2. Solution
    - Add policy for workspace admins to read all users in their workspace
    - Maintain security by restricting to same workspace only
    - Keep existing self-access policy for regular users

  3. Security
    - Workspace admins can only see users in their own workspace
    - Regular users can still only see their own data
    - No cross-workspace data access
*/

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "users_can_read_own_data" ON users;
DROP POLICY IF EXISTS "users_can_update_own_data" ON users;
DROP POLICY IF EXISTS "authenticated_can_insert_users" ON users;

-- Policy 1: Users can read their own data
CREATE POLICY "users_can_read_own_data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 2: Workspace admins can read all users in their workspace
CREATE POLICY "workspace_admins_can_read_workspace_users"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM users admin_user
      JOIN user_roles admin_role ON admin_user.role_id = admin_role.id
      WHERE admin_user.id = auth.uid()
        AND admin_role.name IN ('workspace_admin', 'super_admin')
        AND admin_user.workspace_id = users.workspace_id
    )
  );

-- Policy 3: Users can update their own data
CREATE POLICY "users_can_update_own_data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy 4: Authenticated users can insert new users (for employee creation)
CREATE POLICY "authenticated_can_insert_users"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);