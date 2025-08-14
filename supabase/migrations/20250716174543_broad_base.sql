/*
  # Fix RLS policies for wash_point_services table

  1. Security Updates
    - Drop existing restrictive policies that are causing 403 errors
    - Add new policies that allow workspace admins to manage wash point services
    - Ensure proper workspace isolation and role-based access

  2. New Policies
    - INSERT: Workspace admins can add services to wash points in their workspace
    - UPDATE: Workspace admins can modify wash point services in their workspace  
    - DELETE: Workspace admins can remove services from wash points in their workspace
    - SELECT: All workspace members can read wash point services in their workspace
*/

-- Drop existing policies that may be too restrictive
DROP POLICY IF EXISTS "Workspace admins can manage wash point services" ON wash_point_services;
DROP POLICY IF EXISTS "Workspace members can read wash point services" ON wash_point_services;

-- Create new policies with proper workspace admin access
CREATE POLICY "workspace_admins_can_insert_wash_point_services"
  ON wash_point_services
  FOR INSERT
  TO authenticated
  WITH CHECK (
    wash_point_id IN (
      SELECT wp.id
      FROM workspace_wash_points wp
      JOIN users u ON wp.workspace_id = u.workspace_id
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

CREATE POLICY "workspace_admins_can_update_wash_point_services"
  ON wash_point_services
  FOR UPDATE
  TO authenticated
  USING (
    wash_point_id IN (
      SELECT wp.id
      FROM workspace_wash_points wp
      JOIN users u ON wp.workspace_id = u.workspace_id
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  )
  WITH CHECK (
    wash_point_id IN (
      SELECT wp.id
      FROM workspace_wash_points wp
      JOIN users u ON wp.workspace_id = u.workspace_id
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

CREATE POLICY "workspace_admins_can_delete_wash_point_services"
  ON wash_point_services
  FOR DELETE
  TO authenticated
  USING (
    wash_point_id IN (
      SELECT wp.id
      FROM workspace_wash_points wp
      JOIN users u ON wp.workspace_id = u.workspace_id
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

CREATE POLICY "workspace_members_can_read_wash_point_services"
  ON wash_point_services
  FOR SELECT
  TO authenticated
  USING (
    wash_point_id IN (
      SELECT wp.id
      FROM workspace_wash_points wp
      JOIN users u ON wp.workspace_id = u.workspace_id
      WHERE u.id = auth.uid()
    )
  );