/*
  # Create Users and Roles System

  1. New Tables
    - `user_roles`
      - `id` (uuid, primary key)
      - `name` (text, unique) - Role names: super_admin, workspace_admin, employee
      - `description` (text) - Role description
      - `created_at` (timestamp)
    
    - `users`
      - `id` (uuid, primary key, references auth.users)
      - `email` (text, unique)
      - `full_name` (text)
      - `phone` (text, optional)
      - `role_id` (uuid, references user_roles)
      - `workspace_id` (uuid, optional, will reference workspaces later)
      - `is_active` (boolean, default true)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for role-based access control
    - Super admins can access everything
    - Workspace admins can manage their workspace users
    - Employees can only read their own data

  3. Initial Data
    - Insert default roles (super_admin, workspace_admin, employee)
*/

-- Create user_roles table
CREATE TABLE IF NOT EXISTS user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  phone text,
  role_id uuid REFERENCES user_roles(id) NOT NULL,
  workspace_id uuid, -- Will be foreign key to workspaces table later
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Insert default roles
INSERT INTO user_roles (name, description) VALUES
  ('super_admin', 'Full platform access - can manage all workspaces and users'),
  ('workspace_admin', 'Workspace management - can manage their specific workspace'),
  ('employee', 'Employee access - can manage assigned appointments only')
ON CONFLICT (name) DO NOTHING;

-- RLS Policies for user_roles table
CREATE POLICY "Anyone can read user roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only super admins can modify roles"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() AND ur.name = 'super_admin'
    )
  );

-- RLS Policies for users table
CREATE POLICY "Users can read their own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Super admins can read all users"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() AND ur.name = 'super_admin'
    )
  );

CREATE POLICY "Workspace admins can read users in their workspace"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() 
        AND ur.name = 'workspace_admin'
        AND u.workspace_id = users.workspace_id
    )
  );

CREATE POLICY "Super admins can insert/update/delete all users"
  ON users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() AND ur.name = 'super_admin'
    )
  );

CREATE POLICY "Workspace admins can manage users in their workspace"
  ON users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles ur ON u.role_id = ur.id
      WHERE u.id = auth.uid() 
        AND ur.name = 'workspace_admin'
        AND u.workspace_id = users.workspace_id
    )
  );

CREATE POLICY "Users can update their own profile"
  ON users
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_workspace_id ON users(workspace_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
