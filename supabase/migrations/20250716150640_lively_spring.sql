/*
  # Radical Fix: Completely Disable and Rebuild RLS for Users Table

  This migration takes a radical approach to fix the infinite recursion:
  1. Completely disable RLS on users table
  2. Drop ALL existing policies
  3. Re-enable RLS with only the most basic policy
  4. Ensure related tables have minimal policies for JOINs

  This should eliminate any possibility of recursion.
*/

-- Step 1: Completely disable RLS on users table
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies on users table
DROP POLICY IF EXISTS "users_read_own" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Super admins can read all users" ON users;
DROP POLICY IF EXISTS "Super admins can manage all users" ON users;
DROP POLICY IF EXISTS "Workspace admins can read workspace users" ON users;
DROP POLICY IF EXISTS "Workspace admins can manage workspace users" ON users;

-- Step 3: Drop ALL existing policies on related tables
DROP POLICY IF EXISTS "user_roles_read_all" ON user_roles;
DROP POLICY IF EXISTS "workspaces_read_authenticated" ON workspaces;
DROP POLICY IF EXISTS "Anyone can read user roles" ON user_roles;
DROP POLICY IF EXISTS "Only super admins can modify roles" ON user_roles;
DROP POLICY IF EXISTS "Employees can read their workspace" ON workspaces;
DROP POLICY IF EXISTS "Super admins can manage all workspaces" ON workspaces;
DROP POLICY IF EXISTS "Workspace admins can manage their workspace" ON workspaces;

-- Step 4: Re-enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 5: Create the MOST BASIC policy possible - allow authenticated users to read their own data
CREATE POLICY "basic_user_access" ON users
  FOR ALL
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Step 6: Create basic policies for related tables (needed for JOINs)
CREATE POLICY "basic_roles_read" ON user_roles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "basic_workspaces_read" ON workspaces
  FOR SELECT
  TO authenticated
  USING (true);