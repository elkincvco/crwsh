/*
  # Create workspaces table

  1. New Tables
    - `workspaces`
      - `id` (uuid, primary key)
      - `name` (text, required) - Nombre del negocio/lavadero
      - `description` (text, optional) - Descripción del negocio
      - `address` (text, optional) - Dirección física
      - `phone` (text, optional) - Teléfono de contacto
      - `email` (text, optional) - Email de contacto
      - `logo_url` (text, optional) - URL del logo
      - `is_active` (boolean, default true) - Estado del workspace
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `workspaces` table
    - Super admins can manage all workspaces
    - Workspace admins can only read/update their own workspace
    - Employees can only read their workspace info

  3. Indexes
    - Index on name for search functionality
    - Index on is_active for filtering active workspaces
*/

CREATE TABLE IF NOT EXISTS workspaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  address text,
  phone text,
  email text,
  logo_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_workspaces_name ON workspaces(name);
CREATE INDEX IF NOT EXISTS idx_workspaces_is_active ON workspaces(is_active);

-- RLS Policies

-- Super admins can do everything with workspaces
CREATE POLICY "Super admins can manage all workspaces"
  ON workspaces
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() AND ur.name = 'super_admin'
    )
  );

-- Workspace admins can read and update their own workspace
CREATE POLICY "Workspace admins can manage their workspace"
  ON workspaces
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() 
        AND ur.name = 'workspace_admin' 
        AND u.workspace_id = workspaces.id
    )
  );

-- Employees can read their workspace info
CREATE POLICY "Employees can read their workspace"
  ON workspaces
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.workspace_id = workspaces.id
    )
  );

-- Trigger to update updated_at
CREATE TRIGGER update_workspaces_updated_at
  BEFORE UPDATE ON workspaces
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();