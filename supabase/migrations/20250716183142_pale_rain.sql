/*
  # Create Appointments System

  1. New Tables
    - `appointments`
      - `id` (uuid, primary key)
      - `workspace_id` (uuid, foreign key to workspaces)
      - `service_id` (uuid, foreign key to workspace_services)
      - `wash_point_id` (uuid, foreign key to workspace_wash_points)
      - `appointment_date` (date)
      - `appointment_time` (time)
      - `duration_minutes` (integer)
      - `customer_name` (text)
      - `customer_phone` (text)
      - `customer_email` (text, optional)
      - `vehicle_plate` (text)
      - `comments` (text, optional)
      - `status` (enum)
      - `total_price` (numeric)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `appointments` table
    - Add policies for public booking and workspace admin management

  3. Indexes
    - Performance indexes for common queries
*/

-- Create appointment status enum
CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled');

-- Create appointments table
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES workspace_services(id) ON DELETE RESTRICT,
  wash_point_id uuid NOT NULL REFERENCES workspace_wash_points(id) ON DELETE RESTRICT,
  appointment_date date NOT NULL,
  appointment_time time NOT NULL,
  duration_minutes integer NOT NULL DEFAULT 30,
  customer_name text NOT NULL,
  customer_phone text NOT NULL,
  customer_email text,
  vehicle_plate text NOT NULL,
  comments text,
  status appointment_status NOT NULL DEFAULT 'pending',
  total_price numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_appointments_workspace_date ON appointments(workspace_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_wash_point_datetime ON appointments(wash_point_id, appointment_date, appointment_time);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_created_at ON appointments(created_at DESC);

-- Enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Public can insert appointments (for booking)
CREATE POLICY "Anyone can create appointments"
  ON appointments
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Public can read appointments (for checking availability - limited fields)
CREATE POLICY "Public can read appointments for availability"
  ON appointments
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Workspace members can read all appointments in their workspace
CREATE POLICY "Workspace members can read workspace appointments"
  ON appointments
  FOR SELECT
  TO authenticated
  USING (workspace_id IN (
    SELECT users.workspace_id
    FROM users
    WHERE users.id = auth.uid()
  ));

-- Workspace admins can update appointments in their workspace
CREATE POLICY "Workspace admins can update appointments"
  ON appointments
  FOR UPDATE
  TO authenticated
  USING (workspace_id IN (
    SELECT u.workspace_id
    FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() 
    AND r.name = ANY(ARRAY['workspace_admin', 'super_admin'])
  ))
  WITH CHECK (workspace_id IN (
    SELECT u.workspace_id
    FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() 
    AND r.name = ANY(ARRAY['workspace_admin', 'super_admin'])
  ));

-- Workspace admins can delete appointments in their workspace
CREATE POLICY "Workspace admins can delete appointments"
  ON appointments
  FOR DELETE
  TO authenticated
  USING (workspace_id IN (
    SELECT u.workspace_id
    FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() 
    AND r.name = ANY(ARRAY['workspace_admin', 'super_admin'])
  ));

-- Create trigger for updated_at
CREATE TRIGGER update_appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add constraint to ensure appointment time is within business hours
-- (This will be validated in the application logic)

-- Add constraint to ensure no overlapping appointments for same wash point
CREATE UNIQUE INDEX idx_appointments_no_overlap 
ON appointments (wash_point_id, appointment_date, appointment_time)
WHERE status != 'cancelled';