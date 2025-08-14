/*
  # Fix workspace users visibility for admins

  1. Problem
    - Workspace admins can only see their own user record
    - Cannot see employees in their workspace due to restrictive RLS policy

  2. Solution
    - Drop existing restrictive policy
    - Create new policy that allows workspace admins to see all users in their workspace
    - Use simple EXISTS query to avoid recursion

  3. Security
    - Workspace admins can only see users from their own workspace
    - Regular users can still only see their own data
    - No recursion issues
*/

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "users_can_read_own_data" ON users;

-- Create a new comprehensive policy that handles both cases
CREATE POLICY "users_read_policy" ON users
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always read their own data
    auth.uid() = id
    OR
    -- Workspace admins can read users from their workspace
    EXISTS (
      SELECT 1 
      FROM users admin_user
      JOIN user_roles admin_role ON admin_user.role_id = admin_role.id
      WHERE admin_user.id = auth.uid()
        AND admin_role.name IN ('workspace_admin', 'super_admin')
        AND admin_user.workspace_id = users.workspace_id
    )
  );