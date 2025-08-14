/*
  # Add UPDATE policy for workspaces table

  1. Problem
    - Only SELECT policy exists for workspaces table
    - No UPDATE policy means workspace admins cannot modify workspace data
    - RLS silently blocks UPDATE operations

  2. Solution
    - Add UPDATE policy for workspace admins and super admins
    - Allow them to update their own workspace data
    - Maintain security by restricting to their workspace only

  3. Security
    - Only workspace_admin and super_admin can update
    - Users can only update their assigned workspace
    - Maintains data isolation between workspaces
*/

-- Add UPDATE policy for workspaces table
CREATE POLICY "workspace_admins_can_update_workspace"
  ON workspaces
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  )
  WITH CHECK (
    id IN (
      SELECT u.workspace_id
      FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );