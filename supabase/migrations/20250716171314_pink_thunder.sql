/*
  # Fix RLS policies for workspace_business_hours table

  1. Security Updates
    - Drop existing restrictive policies
    - Create new policies that allow workspace admins to manage business hours
    - Ensure users can only access data from their own workspace

  2. Policy Changes
    - Allow workspace admins and super admins to INSERT, UPDATE, DELETE
    - Allow all workspace members to SELECT (read)
    - Use proper role checking with workspace_id validation
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Workspace admins can manage business hours" ON workspace_business_hours;
DROP POLICY IF EXISTS "Workspace members can read business hours" ON workspace_business_hours;

-- Create new policies with correct permissions

-- Allow workspace members to read business hours from their workspace
CREATE POLICY "workspace_members_can_read_business_hours"
  ON workspace_business_hours
  FOR SELECT
  TO authenticated
  USING (
    workspace_id IN (
      SELECT workspace_id 
      FROM users 
      WHERE id = auth.uid()
    )
  );

-- Allow workspace admins and super admins to insert business hours
CREATE POLICY "workspace_admins_can_insert_business_hours"
  ON workspace_business_hours
  FOR INSERT
  TO authenticated
  WITH CHECK (
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

-- Allow workspace admins and super admins to update business hours
CREATE POLICY "workspace_admins_can_update_business_hours"
  ON workspace_business_hours
  FOR UPDATE
  TO authenticated
  USING (
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  )
  WITH CHECK (
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

-- Allow workspace admins and super admins to delete business hours
CREATE POLICY "workspace_admins_can_delete_business_hours"
  ON workspace_business_hours
  FOR DELETE
  TO authenticated
  USING (
    workspace_id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() 
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );