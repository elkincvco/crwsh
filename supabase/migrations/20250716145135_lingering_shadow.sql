/*
  # Add Foreign Key Constraint Between Users and Workspaces

  1. Changes
    - Add foreign key constraint from users.workspace_id to workspaces.id
    - This will allow Supabase to recognize the relationship for joins

  2. Security
    - No changes to existing RLS policies
    - Maintains data integrity with CASCADE behavior
*/

-- Add foreign key constraint between users and workspaces
ALTER TABLE users 
ADD CONSTRAINT users_workspace_id_fkey 
FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE SET NULL;