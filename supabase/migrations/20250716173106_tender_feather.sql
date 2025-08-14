/*
  # Fix RLS policies for workspace_wash_points table

  1. Problem
    - Users getting "new row violates row-level security policy" error
    - Missing proper INSERT and UPDATE policies for workspace_wash_points table
    - Current policies may be too restrictive or incorrectly configured

  2. Solution
    - Drop existing restrictive policies
    - Create comprehensive policies for all CRUD operations
    - Allow workspace admins and super admins to manage wash points
    - Allow all workspace members to read wash points
    - Ensure proper workspace isolation

  3. Security
    - Users can only access wash points from their own workspace
    - Only workspace_admin and super_admin roles can modify data
    - All workspace members can read wash points
*/

-- Drop existing policies that might be causing issues
DROP POLICY IF EXISTS "Workspace admins can manage wash points" ON workspace_wash_points;
DROP POLICY IF EXISTS "Workspace members can read wash points" ON workspace_wash_points;

-- Create comprehensive policies for workspace_wash_points table

-- Allow all workspace members to read wash points from their workspace
CREATE POLICY "workspace_members_can_read_wash_points"
  ON workspace_wash_points
  FOR SELECT
  TO authenticated
  USING (
    workspace_id IN (
      SELECT users.workspace_id
      FROM users
      WHERE users.id = auth.uid()
    )
  );

-- Allow workspace admins and super admins to insert wash points in their workspace
CREATE POLICY "workspace_admins_can_insert_wash_points"
  ON workspace_wash_points
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

-- Allow workspace admins and super admins to update wash points in their workspace
CREATE POLICY "workspace_admins_can_update_wash_points"
  ON workspace_wash_points
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

-- Allow workspace admins and super admins to delete wash points in their workspace
CREATE POLICY "workspace_admins_can_delete_wash_points"
  ON workspace_wash_points
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