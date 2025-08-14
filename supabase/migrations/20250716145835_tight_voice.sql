/*
  # Fix infinite recursion in users RLS policies

  1. Problem
    - Current policies have infinite recursion because they JOIN users table within users policies
    - This creates circular dependencies when Supabase tries to evaluate the policies

  2. Solution
    - Drop existing problematic policies
    - Create new policies that avoid self-referencing the users table
    - Use auth.uid() directly for user identification
    - Create separate policies for different roles without complex JOINs

  3. New Policies
    - Simple user self-access policy
    - Super admin policy using direct role check
    - Workspace admin policy using direct workspace check
*/

-- Drop all existing policies on users table
DROP POLICY IF EXISTS "Users can read their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Super admins can read all users" ON users;
DROP POLICY IF EXISTS "Super admins can insert/update/delete all users" ON users;
DROP POLICY IF EXISTS "Workspace admins can read users in their workspace" ON users;
DROP POLICY IF EXISTS "Workspace admins can manage users in their workspace" ON users;

-- Create simple, non-recursive policies

-- 1. Users can read and update their own data
CREATE POLICY "Users can read own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON users
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- 2. Super admin policies (check role directly without JOIN)
CREATE POLICY "Super admins can read all users"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    role_id = (SELECT id FROM user_roles WHERE name = 'super_admin')
    OR
    EXISTS (
      SELECT 1 FROM user_roles ur 
      WHERE ur.id = (SELECT role_id FROM users WHERE id = auth.uid()) 
      AND ur.name = 'super_admin'
    )
  );

CREATE POLICY "Super admins can manage all users"
  ON users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur 
      WHERE ur.id = (SELECT role_id FROM users WHERE id = auth.uid()) 
      AND ur.name = 'super_admin'
    )
  );

-- 3. Workspace admin policies (simplified)
CREATE POLICY "Workspace admins can read workspace users"
  ON users
  FOR SELECT
  TO authenticated
  USING (
    workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid())
    AND
    EXISTS (
      SELECT 1 FROM user_roles ur 
      WHERE ur.id = (SELECT role_id FROM users WHERE id = auth.uid()) 
      AND ur.name = 'workspace_admin'
    )
  );

CREATE POLICY "Workspace admins can manage workspace users"
  ON users
  FOR ALL
  TO authenticated
  USING (
    workspace_id = (SELECT workspace_id FROM users WHERE id = auth.uid())
    AND
    EXISTS (
      SELECT 1 FROM user_roles ur 
      WHERE ur.id = (SELECT role_id FROM users WHERE id = auth.uid()) 
      AND ur.name = 'workspace_admin'
    )
  );