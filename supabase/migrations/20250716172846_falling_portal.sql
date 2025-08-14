/*
  # Fix RLS policies for workspace_services table

  1. Problem
    - Users getting "new row violates row-level security policy" when saving services
    - Missing INSERT and UPDATE policies for workspace_services table
    - Only SELECT policy exists, but users need to create/modify services

  2. Solution
    - Add INSERT policy for workspace admins and super admins
    - Add UPDATE policy for workspace admins and super admins  
    - Add DELETE policy for workspace admins and super admins
    - Ensure users can only manage services in their own workspace

  3. Security
    - Only workspace_admin and super_admin roles can manage services
    - Users can only access services from their assigned workspace
    - Maintains data isolation between workspaces
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Workspace admins can manage services" ON workspace_services;
DROP POLICY IF EXISTS "Workspace members can read services" ON workspace_services;

-- Create comprehensive policies for workspace_services table

-- Allow workspace members to read services from their workspace
CREATE POLICY "workspace_members_can_read_services"
  ON workspace_services
  FOR SELECT
  TO authenticated
  USING (
    workspace_id IN (
      SELECT users.workspace_id
      FROM users
      WHERE users.id = auth.uid()
    )
  );

-- Allow workspace admins and super admins to insert services in their workspace
CREATE POLICY "workspace_admins_can_insert_services"
  ON workspace_services
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

-- Allow workspace admins and super admins to update services in their workspace
CREATE POLICY "workspace_admins_can_update_services"
  ON workspace_services
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

-- Allow workspace admins and super admins to delete services in their workspace
CREATE POLICY "workspace_admins_can_delete_services"
  ON workspace_services
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