/*
  # Create employee daily status table

  1. New Tables
    - `employee_daily_status`
      - `employee_id` (uuid, foreign key to users)
      - `date` (date)
      - `is_active` (boolean, default true)
      - Composite primary key on (employee_id, date)

  2. Security
    - Enable RLS on `employee_daily_status` table
    - Add policy for authenticated users to read all status records
    - Add policy for employees to insert/update their own status
    - Add policy for workspace admins to read status from their workspace employees

  3. Purpose
    - Track employee availability status per day
    - Allow employees to mark themselves as active/inactive for specific dates
    - Default to active status for new dates
*/

CREATE TABLE IF NOT EXISTS employee_daily_status (
  employee_id uuid NOT NULL,
  date date NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (employee_id, date)
);

-- Add foreign key constraint
ALTER TABLE employee_daily_status 
ADD CONSTRAINT employee_daily_status_employee_id_fkey 
FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_employee_daily_status_employee_date 
ON employee_daily_status(employee_id, date);

CREATE INDEX IF NOT EXISTS idx_employee_daily_status_date 
ON employee_daily_status(date);

-- Enable Row Level Security
ALTER TABLE employee_daily_status ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all status records
CREATE POLICY "authenticated_users_can_read_employee_status"
  ON employee_daily_status
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow employees to insert their own status
CREATE POLICY "employees_can_insert_own_status"
  ON employee_daily_status
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = employee_id);

-- Policy: Allow employees to update their own status
CREATE POLICY "employees_can_update_own_status"
  ON employee_daily_status
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = employee_id)
  WITH CHECK (auth.uid() = employee_id);

-- Policy: Allow workspace admins to read status from their workspace employees
CREATE POLICY "workspace_admins_can_read_employee_status"
  ON employee_daily_status
  FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT u.id
      FROM users u
      JOIN users admin ON admin.workspace_id = u.workspace_id
      JOIN user_roles r ON admin.role_id = r.id
      WHERE admin.id = auth.uid()
      AND r.name IN ('workspace_admin', 'super_admin')
    )
  );

-- Add trigger for updated_at
CREATE TRIGGER update_employee_daily_status_updated_at
  BEFORE UPDATE ON employee_daily_status
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();