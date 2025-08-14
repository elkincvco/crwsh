/*
  # Insert authenticated users into users table

  1. Users Created
    - Super Admin: elkinescobarbo@gmail.com
    - Admin Lavadero Express: admin@lavadero1.com  
    - Admin AutoLavado Premium: admin@lavadero2.com
    - Empleado Lavadero Express: empleado@lavader1.com
    - Empleado AutoLavado Premium: empleado@lavadero2.com

  2. Assignments
    - Super admin has no workspace (can manage all)
    - Admins assigned to their respective workspaces
    - Employees assigned to their respective workspaces

  3. Security
    - All users are active by default
    - Proper role assignments for access control
*/

-- Get role IDs for reference
DO $$
DECLARE
    super_admin_role_id uuid;
    workspace_admin_role_id uuid;
    employee_role_id uuid;
    lavadero_express_id uuid;
    autolavado_premium_id uuid;
BEGIN
    -- Get role IDs
    SELECT id INTO super_admin_role_id FROM user_roles WHERE name = 'super_admin';
    SELECT id INTO workspace_admin_role_id FROM user_roles WHERE name = 'workspace_admin';
    SELECT id INTO employee_role_id FROM user_roles WHERE name = 'employee';
    
    -- Get workspace IDs
    SELECT id INTO lavadero_express_id FROM workspaces WHERE name = 'Lavadero Express';
    SELECT id INTO autolavado_premium_id FROM workspaces WHERE name = 'AutoLavado Premium';

    -- Insert Super Admin
    INSERT INTO users (
        id,
        email,
        full_name,
        phone,
        role_id,
        workspace_id,
        is_active
    ) VALUES (
        '0319d2f3-cfa9-4f43-a068-004b9e538804',
        'elkinescobarbo@gmail.com',
        'Elkin Escobar',
        '+57 300 123 4567',
        super_admin_role_id,
        NULL, -- Super admin has no specific workspace
        true
    );

    -- Insert Admin for Lavadero Express
    INSERT INTO users (
        id,
        email,
        full_name,
        phone,
        role_id,
        workspace_id,
        is_active
    ) VALUES (
        '5ecd669c-48b7-4448-9bc1-1a59314f6176',
        'admin@lavadero1.com',
        'Ana Martinez',
        '+57 301 234 5678',
        workspace_admin_role_id,
        lavadero_express_id,
        true
    );

    -- Insert Admin for AutoLavado Premium
    INSERT INTO users (
        id,
        email,
        full_name,
        phone,
        role_id,
        workspace_id,
        is_active
    ) VALUES (
        '311f6c43-b6ac-4af7-9e35-ccc71f9a15ed',
        'admin@lavadero2.com',
        'Luis Garcia',
        '+57 302 345 6789',
        workspace_admin_role_id,
        autolavado_premium_id,
        true
    );

    -- Insert Employee for Lavadero Express
    INSERT INTO users (
        id,
        email,
        full_name,
        phone,
        role_id,
        workspace_id,
        is_active
    ) VALUES (
        'fcde2893-e9b2-4e1c-aa8c-f0140a8f99a2',
        'empleado@lavader1.com',
        'Pedro Sanchez',
        '+57 303 456 7890',
        employee_role_id,
        lavadero_express_id,
        true
    );

    -- Insert Employee for AutoLavado Premium
    INSERT INTO users (
        id,
        email,
        full_name,
        phone,
        role_id,
        workspace_id,
        is_active
    ) VALUES (
        'a362a200-92dd-4c36-af3b-6ddabb9e5e64',
        'empleado@lavadero2.com',
        'Maria Lopez',
        '+57 304 567 8901',
        employee_role_id,
        autolavado_premium_id,
        true
    );

END $$;