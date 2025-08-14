/*
  # Business Configuration System

  1. New Tables
    - `workspace_business_hours` - Store business hours for each workspace
    - `workspace_services` - Store services offered by each workspace  
    - `workspace_wash_points` - Store wash points for each workspace
    - `wash_point_services` - Many-to-many relationship between wash points and services

  2. Security
    - Enable RLS on all new tables
    - Add policies for workspace admins to manage their data
    - Add read policies for workspace members

  3. Changes
    - Add welcome_message field to workspaces table
    - Add business_hours_info field to workspaces table
*/

-- Add new fields to workspaces table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workspaces' AND column_name = 'welcome_message'
  ) THEN
    ALTER TABLE workspaces ADD COLUMN welcome_message text DEFAULT 'Bienvenido a nuestro workspace';
  END IF;
END $$;

-- Create workspace_business_hours table
CREATE TABLE IF NOT EXISTS workspace_business_hours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  day_of_week integer NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday, 6=Saturday
  is_open boolean DEFAULT false,
  morning_open_time time,
  morning_close_time time,
  afternoon_open_time time,
  afternoon_close_time time,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(workspace_id, day_of_week)
);

-- Create workspace_services table
CREATE TABLE IF NOT EXISTS workspace_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  price numeric(10,2) NOT NULL DEFAULT 0,
  duration_minutes integer NOT NULL DEFAULT 30,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create workspace_wash_points table
CREATE TABLE IF NOT EXISTS workspace_wash_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  is_active boolean DEFAULT true,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create wash_point_services junction table
CREATE TABLE IF NOT EXISTS wash_point_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  wash_point_id uuid NOT NULL REFERENCES workspace_wash_points(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES workspace_services(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(wash_point_id, service_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workspace_business_hours_workspace ON workspace_business_hours(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_services_workspace ON workspace_services(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_wash_points_workspace ON workspace_wash_points(workspace_id);
CREATE INDEX IF NOT EXISTS idx_wash_point_services_wash_point ON wash_point_services(wash_point_id);
CREATE INDEX IF NOT EXISTS idx_wash_point_services_service ON wash_point_services(service_id);

-- Enable RLS
ALTER TABLE workspace_business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_wash_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE wash_point_services ENABLE ROW LEVEL SECURITY;

-- Create policies for workspace_business_hours
CREATE POLICY "Workspace members can read business hours"
  ON workspace_business_hours
  FOR SELECT
  TO authenticated
  USING (workspace_id IN (
    SELECT workspace_id FROM users WHERE id = auth.uid()
  ));

CREATE POLICY "Workspace admins can manage business hours"
  ON workspace_business_hours
  FOR ALL
  TO authenticated
  USING (workspace_id IN (
    SELECT u.workspace_id FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ))
  WITH CHECK (workspace_id IN (
    SELECT u.workspace_id FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ));

-- Create policies for workspace_services
CREATE POLICY "Workspace members can read services"
  ON workspace_services
  FOR SELECT
  TO authenticated
  USING (workspace_id IN (
    SELECT workspace_id FROM users WHERE id = auth.uid()
  ));

CREATE POLICY "Workspace admins can manage services"
  ON workspace_services
  FOR ALL
  TO authenticated
  USING (workspace_id IN (
    SELECT u.workspace_id FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ))
  WITH CHECK (workspace_id IN (
    SELECT u.workspace_id FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ));

-- Create policies for workspace_wash_points
CREATE POLICY "Workspace members can read wash points"
  ON workspace_wash_points
  FOR SELECT
  TO authenticated
  USING (workspace_id IN (
    SELECT workspace_id FROM users WHERE id = auth.uid()
  ));

CREATE POLICY "Workspace admins can manage wash points"
  ON workspace_wash_points
  FOR ALL
  TO authenticated
  USING (workspace_id IN (
    SELECT u.workspace_id FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ))
  WITH CHECK (workspace_id IN (
    SELECT u.workspace_id FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ));

-- Create policies for wash_point_services
CREATE POLICY "Workspace members can read wash point services"
  ON wash_point_services
  FOR SELECT
  TO authenticated
  USING (wash_point_id IN (
    SELECT wp.id FROM workspace_wash_points wp
    JOIN users u ON wp.workspace_id = u.workspace_id
    WHERE u.id = auth.uid()
  ));

CREATE POLICY "Workspace admins can manage wash point services"
  ON wash_point_services
  FOR ALL
  TO authenticated
  USING (wash_point_id IN (
    SELECT wp.id FROM workspace_wash_points wp
    JOIN users u ON wp.workspace_id = u.workspace_id
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ))
  WITH CHECK (wash_point_id IN (
    SELECT wp.id FROM workspace_wash_points wp
    JOIN users u ON wp.workspace_id = u.workspace_id
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  ));

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_workspace_business_hours_updated_at
    BEFORE UPDATE ON workspace_business_hours
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workspace_services_updated_at
    BEFORE UPDATE ON workspace_services
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workspace_wash_points_updated_at
    BEFORE UPDATE ON workspace_wash_points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();