/*
  # Fix infinite recursion in users RLS policy

  1. Problem
    - The current RLS policy causes infinite recursion when checking workspace admin permissions
    - The policy queries the users table within itself, creating a circular dependency

  2. Solution
    - Drop the problematic policy that causes recursion
    - Create a simple, non-recursive policy structure
    - Use direct auth.uid() checks without complex joins

  3. Security
    - Users can read their own data
    - Workspace admins can read users from their workspace (handled at application level)
    - No recursive queries in RLS policies
*/

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "users_read_policy" ON users;

-- Create a simple, non-recursive policy for users to read their own data
CREATE POLICY "users_can_read_own_data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Keep the existing update policy (it's safe)
-- Keep the existing insert policy (it's safe)