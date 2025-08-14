/*
  # Fix infinite recursion in RLS policies

  1. Problem
    - The workspace_admins_can_read_workspace_users policy is causing infinite recursion
    - The policy joins users table with itself through user_roles, creating a circular dependency
    - This happens when the policy tries to validate if the current user is a workspace_admin

  2. Solution
    - Drop the problematic policy that causes recursion
    - Create a simpler policy that doesn't create circular dependencies
    - Use auth.uid() directly without complex joins that reference the same table

  3. Security
    - Maintain proper access control
    - Users can still read their own data
    - Workspace functionality will work through application logic rather than complex RLS
*/

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "workspace_admins_can_read_workspace_users" ON users;

-- Keep the basic policies that don't cause recursion
-- Users can read their own data (this works fine)
-- Users can update their own data (this works fine)
-- Authenticated users can insert users (this works fine)

-- For workspace admin functionality, we'll handle permissions in the application layer
-- rather than through complex RLS policies that cause recursion

-- Ensure the basic policies are in place
DO $$
BEGIN
  -- Policy for users to read their own data
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' 
    AND policyname = 'users_can_read_own_data'
  ) THEN
    CREATE POLICY "users_can_read_own_data"
      ON users
      FOR SELECT
      TO authenticated
      USING (auth.uid() = id);
  END IF;

  -- Policy for users to update their own data
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' 
    AND policyname = 'users_can_update_own_data'
  ) THEN
    CREATE POLICY "users_can_update_own_data"
      ON users
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;

  -- Policy for authenticated users to insert users
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' 
    AND policyname = 'authenticated_can_insert_users'
  ) THEN
    CREATE POLICY "authenticated_can_insert_users"
      ON users
      FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;
END $$;