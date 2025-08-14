/*
  # Create workspace content and activity tables

  1. New Tables
    - `workspace_stats`
      - `id` (uuid, primary key)
      - `workspace_id` (uuid, foreign key to workspaces)
      - `metric_name` (text) - e.g., 'cars_washed_today', 'revenue_month'
      - `value` (numeric)
      - `date` (date)
      - `created_at` (timestamp)
    
    - `workspace_activities`
      - `id` (uuid, primary key)
      - `workspace_id` (uuid, foreign key to workspaces)
      - `user_id` (uuid, foreign key to users)
      - `action` (text) - e.g., 'car_washed', 'payment_received'
      - `description` (text)
      - `metadata` (jsonb) - additional data
      - `created_at` (timestamp)
    
    - `workspace_content`
      - `id` (uuid, primary key)
      - `workspace_id` (uuid, foreign key to workspaces)
      - `title` (text)
      - `content` (text)
      - `type` (text) - e.g., 'announcement', 'info', 'alert'
      - `is_active` (boolean)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for workspace-based access
    
  3. Sample Data
    - Insert test data for existing workspaces
*/

-- Create workspace_stats table
CREATE TABLE IF NOT EXISTS workspace_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  metric_name text NOT NULL,
  value numeric NOT NULL DEFAULT 0,
  date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now()
);

-- Create workspace_activities table
CREATE TABLE IF NOT EXISTS workspace_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action text NOT NULL,
  description text NOT NULL,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Create workspace_content table
CREATE TABLE IF NOT EXISTS workspace_content (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text NOT NULL,
  type text NOT NULL DEFAULT 'info',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_workspace_stats_workspace_date ON workspace_stats(workspace_id, date);
CREATE INDEX IF NOT EXISTS idx_workspace_activities_workspace_created ON workspace_activities(workspace_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workspace_content_workspace_active ON workspace_content(workspace_id, is_active);

-- Enable RLS
ALTER TABLE workspace_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_content ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workspace_stats
CREATE POLICY "Users can read stats from their workspace"
  ON workspace_stats FOR SELECT TO authenticated
  USING (
    workspace_id IN (
      SELECT workspace_id FROM users WHERE id = auth.uid()
    )
  );

-- RLS Policies for workspace_activities
CREATE POLICY "Users can read activities from their workspace"
  ON workspace_activities FOR SELECT TO authenticated
  USING (
    workspace_id IN (
      SELECT workspace_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can insert activities in their workspace"
  ON workspace_activities FOR INSERT TO authenticated
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM users WHERE id = auth.uid()
    )
  );

-- RLS Policies for workspace_content
CREATE POLICY "Users can read content from their workspace"
  ON workspace_content FOR SELECT TO authenticated
  USING (
    workspace_id IN (
      SELECT workspace_id FROM users WHERE id = auth.uid()
    )
  );

-- Insert sample data for existing workspaces
DO $$
DECLARE
  workspace_record RECORD;
  sample_user_id uuid;
BEGIN
  -- Get a sample user for activities
  SELECT id INTO sample_user_id FROM users LIMIT 1;
  
  -- Insert sample data for each workspace
  FOR workspace_record IN SELECT id, name FROM workspaces WHERE is_active = true
  LOOP
    -- Insert sample stats
    INSERT INTO workspace_stats (workspace_id, metric_name, value, date) VALUES
      (workspace_record.id, 'cars_washed_today', floor(random() * 50 + 10), CURRENT_DATE),
      (workspace_record.id, 'revenue_today', floor(random() * 5000 + 1000), CURRENT_DATE),
      (workspace_record.id, 'cars_washed_month', floor(random() * 800 + 200), CURRENT_DATE),
      (workspace_record.id, 'revenue_month', floor(random() * 80000 + 20000), CURRENT_DATE),
      (workspace_record.id, 'active_employees', floor(random() * 10 + 3), CURRENT_DATE);
    
    -- Insert sample content
    INSERT INTO workspace_content (workspace_id, title, content, type) VALUES
      (workspace_record.id, 'Bienvenido a ' || workspace_record.name, 'Sistema de gestión integral para tu lavadero. Aquí puedes monitorear todas las actividades diarias.', 'info'),
      (workspace_record.id, 'Horarios de Atención', 'Lunes a Viernes: 8:00 AM - 6:00 PM\nSábados: 8:00 AM - 4:00 PM\nDomingos: Cerrado', 'announcement'),
      (workspace_record.id, 'Promoción del Mes', '¡Lavado completo + encerado por solo $25! Válido hasta fin de mes.', 'alert');
    
    -- Insert sample activities (only if we have a user)
    IF sample_user_id IS NOT NULL THEN
      INSERT INTO workspace_activities (workspace_id, user_id, action, description, metadata) VALUES
        (workspace_record.id, sample_user_id, 'car_washed', 'Lavado completo - Toyota Corolla', '{"service_type": "complete", "price": 20}'),
        (workspace_record.id, sample_user_id, 'payment_received', 'Pago recibido por servicios', '{"amount": 20, "method": "cash"}'),
        (workspace_record.id, sample_user_id, 'employee_checkin', 'Empleado inició turno', '{"shift": "morning"}');
    END IF;
  END LOOP;
END $$;