/*
  # Fix infinite recursion in users table RLS policies

  1. Problem
    - Current policies create infinite recursion by querying users table within users policies
    - Error: "infinite recursion detected in policy for relation users"

  2. Solution
    - Remove all existing policies that cause recursion
    - Implement simple, non-recursive policies
    - Use auth.uid() directly instead of complex subqueries

  3. New Policies
    - Simple SELECT policy: users can read their own data
    - Simple INSERT policy: authenticated users can insert (with role validation in app)
    - Simple UPDATE policy: users can update their own data
    - Admin operations handled at application level
*/

-- Drop all existing policies that might cause recursion
DROP POLICY IF EXISTS "users_can_read_data" ON users;
DROP POLICY IF EXISTS "users_can_update_data" ON users;
DROP POLICY IF EXISTS "admins_can_insert_users" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "users_delete_policy" ON users;

-- Simple, non-recursive policies
CREATE POLICY "users_can_read_own_data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "users_can_update_own_data"
  ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert (role validation handled in application)
CREATE POLICY "authenticated_can_insert_users"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);